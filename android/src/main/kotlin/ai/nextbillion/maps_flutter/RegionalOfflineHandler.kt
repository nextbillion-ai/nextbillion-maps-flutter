package ai.nextbillion.maps_flutter

import android.app.Application
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import ai.nextbillion.maps.Nextbillion
import ai.nextbillion.maps.regionaloffline.release.client.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect
import java.util.concurrent.atomic.AtomicInteger

/** Owns Flutter subscriptions/page sessions; the SDK retains the download runtime. */
class RegionalOfflineHandler(messenger: BinaryMessenger, private val application: Application) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private val configuring = AtomicInteger()
        @JvmStatic fun isConfiguring(): Boolean = configuring.get() > 0
    }
    private val methods = MethodChannel(messenger, "plugins.flutter.io/nb_maps_flutter/regional_offline")
    private val events = EventChannel(messenger, "plugins.flutter.io/nb_maps_flutter/regional_offline/events")
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var sink: EventChannel.EventSink? = null
    private var previewJob: Job? = null
    private var progressAttached = false
    private var hostLifecycle: Lifecycle? = null
    private var pageOwner: PageOwner? = null
    private var pageId: String? = null
    private var closed = false
    private val progressListener = OfflineDownloadProgressListener { progress ->
        emit("downloadProgress", progress.values.sortedBy { it.regionId }.map(::progressMap))
    }

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    fun onHostLifecycleChanged(lifecycle: Lifecycle?) {
        if (closed) return
        closePageOwner()
        hostLifecycle = lifecycle
        if (pageId != null && lifecycle != null && lifecycle.currentState != Lifecycle.State.DESTROYED) {
            openPageOwner(lifecycle)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (closed) return
        scope.launch {
            try {
                val value: Any? = when (call.method) {
                    "supportStatus" -> RegionalOffline.supportStatus().name
                    "endDownloadPage" -> {
                        if (pageId == call.argument<String>("pageId")) { closePageOwner(); pageId = null }
                        null
                    }
                    "configure" -> {
                        requireSupported()
                        val url = call.argument<String>("mapsBaseUrl")
                        // SDK initialization is thread-safe. Keep session setup and any
                        // cold storage work off the map/platform-view thread.
                        configuring.incrementAndGet()
                        val initialized = try {
                            withContext(Dispatchers.IO) {
                                if (url == null) RegionalOffline.initialize(application)
                                else RegionalOffline.initialize(application, url)
                            }
                        } finally {
                            configuring.decrementAndGet()
                        }
                        if (!initialized) throw BridgeFailure("CONFIGURATION_FAILED",
                            "Regional Offline could not be initialized. A different CDN requires app restart.")
                        attachListeners()
                        null
                    }
                    else -> {
                        requireConfigured()
                        when (call.method) {
                            "fetchRegionList" -> {
                                val country = call.argument<String>("country").orEmpty().trim()
                                val items = if (country.isEmpty()) RegionalOffline.fetchRegionList().getOrThrow()
                                    else RegionalOffline.fetchRegionList(country).getOrThrow()
                                items.map(::catalogMap)
                            }
                            "queryRegions" -> RegionalOffline.queryRegions().getOrThrow().let {
                                mapOf("catalog" to it.catalog.map(::catalogMap),
                                    "installed" to it.installed.map(::installedMap),
                                    "previewStylesReady" to it.previewStylesReady, "displayReady" to it.displayReady,
                                    "canBindOfflineMap" to it.canBindOfflineMap, "readinessIsBundleOnly" to false)
                            }
                            "fetchRegionDetail" -> detailResultMap(RegionalOffline.fetchRegionDetail(regionId(call)).getOrThrow())
                            "loadOfflineDetail" -> withContext(Dispatchers.IO) {
                                detailResultMap(RegionalOffline.loadOfflineDetail(regionId(call)))
                            }
                            "listInstalledRegions" -> withContext(Dispatchers.IO) {
                                RegionalOffline.listInstalledRegions().map(::installedMap)
                            }
                            "hasInstalledRegions" -> withContext(Dispatchers.IO) { RegionalOffline.hasInstalledOfflineRegions() }
                            "offlinePreviewResourceStatus" -> withContext(Dispatchers.IO) {
                                RegionalOffline.offlinePreviewResourceStatus().let {
                                    mapOf("previewBundleReady" to RegionalOffline.previewBundleImportStatus().previewBundleReady,
                                        "previewStylesReady" to it.previewStylesReady, "styleJsonCached" to it.styleJsonCached,
                                        "spritesReady" to it.spritesReady, "tileJsonReady" to it.tileJsonReady,
                                        "displayReady" to it.displayReady, "canEnqueueRegionDownload" to it.canEnqueueRegionDownload,
                                        "canBindOfflineMap" to it.canBindOfflineMap,
                                        "cachedPreviewStyleNames" to it.cachedPreviewStyleNames, "readinessIsBundleOnly" to false)
                                }
                            }
                            "getPreviewBundleImportStatus" -> previewMap(RegionalOffline.previewBundleImportStatus())
                            "getDownloadProgress" -> RegionalOffline.downloadProgress.value.values.sortedBy { it.regionId }.map(::progressMap)
                            "downloadRegion" -> {
                                RegionalOffline.download(regionId(call), call.argument<Boolean>("clearBefore") ?: false).getOrThrow()
                                null
                            }
                            "controlDownload" -> {
                                val action = when (call.argument<String>("action")) {
                                    "pause" -> DownloadAction.PAUSE
                                    "resume" -> DownloadAction.RESUME
                                    "cancel" -> DownloadAction.CANCEL
                                    "delete" -> DownloadAction.DELETE
                                    else -> throw BridgeFailure("INVALID_ARGUMENT", "Unknown download action")
                                }
                                RegionalOffline.controlDownload(regionId(call), action)
                                null
                            }
                            "beginDownloadPage" -> {
                                val id = call.argument<String>("pageId")?.takeIf { it.isNotBlank() }
                                    ?: throw BridgeFailure("INVALID_ARGUMENT", "pageId is required")
                                val lifecycle = hostLifecycle?.takeIf { it.currentState != Lifecycle.State.DESTROYED }
                                    ?: throw BridgeFailure("NO_ACTIVITY", "A foreground Activity is required")
                                closePageOwner()
                                pageId = id
                                openPageOwner(lifecycle)
                                null
                            }
                            "refreshEngine" -> {
                                RegionalOffline.refreshEngineOnMapResume(application)
                                null
                            }
                            else -> { result.notImplemented(); return@launch }
                        }
                    }
                }
                if (!closed) result.success(value)
            } catch (error: CancellationException) {
                if (!closed) result.error("CANCELLED", "Regional Offline operation was cancelled", null)
            } catch (error: Exception) {
                val code = when (error) {
                    is BridgeFailure -> error.code
                    is OfflineRegionError -> error.errorCode
                    is IllegalArgumentException -> "INVALID_ARGUMENT"
                    else -> "REGIONAL_OFFLINE_ERROR"
                }
                if (!closed) result.error(code, error.message, mapOf("nativeType" to error.javaClass.simpleName))
            }
        }
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        sink = eventSink
        attachListeners()
    }

    override fun onCancel(arguments: Any?) {
        detachListeners()
        sink = null
    }

    fun dispose() {
        closePageOwner()
        pageId = null
        detachListeners()
        closed = true
        sink = null
        scope.cancel()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    private fun attachListeners() {
        if (sink == null || progressAttached || !RegionalOffline.isInitialized()) return
        progressAttached = true
        RegionalOffline.addDownloadProgressListener(progressListener)
        previewJob = scope.launch {
            RegionalOffline.previewBundleImportStatus.collect { emit("previewBundleImportStatus", previewMap(it)) }
        }
    }

    private fun detachListeners() {
        if (progressAttached) RegionalOffline.removeDownloadProgressListener(progressListener)
        progressAttached = false
        previewJob?.cancel()
        previewJob = null
    }

    private fun emit(type: String, data: Any) { sink?.success(mapOf("type" to type, "data" to data)) }

    private fun requireSupported() {
        if (!Nextbillion.hasInstance()) throw BridgeFailure("NOT_INITIALIZED", "Initialize NextBillion first")
        if (!RegionalOffline.isSupported()) throw BridgeFailure("UNSUPPORTED_TILE_SERVER", "Regional Offline requires TomTom")
    }

    private fun requireConfigured() {
        requireSupported()
        if (!RegionalOffline.isInitialized()) throw BridgeFailure("NOT_INITIALIZED", "Call RegionalOffline.configure first")
    }

    private fun regionId(call: MethodCall): Int = (call.argument<Any>("regionId") as? Number)?.let {
        val id = it.toLong()
        if (id < 0 || id > Int.MAX_VALUE || it.toDouble() != id.toDouble()) {
            throw BridgeFailure("INVALID_ARGUMENT", "regionId must be a nonnegative 32-bit integer")
        }
        id.toInt()
    } ?: throw BridgeFailure("INVALID_ARGUMENT", "regionId is required")

    private fun openPageOwner(lifecycle: Lifecycle) {
        pageOwner = PageOwner(lifecycle).also { RegionalOffline.beginDownloadPage(it) }
    }
    private fun closePageOwner() {
        val owner = pageOwner ?: return
        pageOwner = null
        try { RegionalOffline.endDownloadPage(owner) } finally { owner.close() }
    }

    private class PageOwner(private val host: Lifecycle) : LifecycleOwner, LifecycleEventObserver {
        private val registry = LifecycleRegistry(this)
        override val lifecycle: Lifecycle get() = registry
        init { host.addObserver(this); registry.currentState = host.currentState }
        override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
            registry.currentState = source.lifecycle.currentState
        }
        fun close() {
            host.removeObserver(this)
            if (registry.currentState == Lifecycle.State.INITIALIZED) registry.currentState = Lifecycle.State.CREATED
            registry.currentState = Lifecycle.State.DESTROYED
        }
    }

    private class BridgeFailure(val code: String, message: String) : Exception(message)

    private fun catalogMap(it: OfflineCatalogItem): Map<String, Any?> = mapOf(
        "regionId" to it.regionId, "name" to it.name, "adminL0" to it.adminL0, "adminL1" to it.adminL1,
        "adminL3" to it.adminL3, "version" to it.version, "totalSize" to it.totalSize,
        "tileCount" to it.tileCount, "timestamp" to it.timestamp)

    private fun installedMap(it: OfflineInstalledRegion): Map<String, Any?> = mapOf(
        "regionId" to it.regionId, "displayName" to it.displayName, "packageCount" to it.packageCount,
        "totalBytes" to it.totalBytes, "regionVersion" to it.regionVersion, "allTarsOk" to it.allTarsOk,
        "dataSourceId" to it.dataSource.id, "dataSourceLabel" to it.dataSourceLabel)

    private fun detailResultMap(it: OfflineRegionDetailResult): Map<String, Any?> = mapOf(
        "detailJson" to it.detailJson, "detail" to it.detail?.let { detail -> mapOf(
            "regionId" to detail.regionId, "version" to detail.version, "country" to detail.country,
            "adminL1" to detail.adminL1, "adminL2" to detail.adminL2, "adminL3" to detail.adminL3,
            "timestamp" to detail.timestamp, "totalSize" to detail.totalSize,
            "packages" to detail.packages.map { p -> mapOf("tarName" to p.tarName,
                "version" to p.version, "tarSize" to p.tarSize, "timestamp" to p.timestamp,
                "minZoom" to p.minZoom, "maxZoom" to p.maxZoom) }) })

    private fun progressMap(it: OfflineDownloadProgress): Map<String, Any?> = mapOf(
        "regionId" to it.regionId, "state" to it.state.name, "downloadedBytes" to it.downloadedBytes,
        "totalBytes" to it.totalBytes, "currentPackageName" to it.currentPackageName,
        "errorMessage" to it.errorMessage, "percent" to it.percent)

    private fun previewMap(it: PreviewBundleImportStatus): Map<String, Any?> = mapOf(
        "previewBundleReady" to it.previewBundleReady, "ensuring" to it.ensuring,
        "waitingForNetwork" to it.waitingForNetwork, "lastErrorCode" to it.lastErrorCode,
        "lastErrorMessage" to it.lastErrorMessage, "recoverable" to it.recoverable)
}
