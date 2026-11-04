//
//  OfflineChannelHandler.swift
//  location
//
//  Created by Patryk on 03/06/2020.
//

import Flutter
import Foundation

class OfflineChannelHandler: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private let eventChannel: FlutterEventChannel
    private var buffered: [(String, Any)] = []
    private var finished = false
    private let enabled: Bool
    var onDisposed: (() -> Void)?

    init(messenger: FlutterBinaryMessenger, channelName: String, enabled: Bool = true) {
        self.enabled = enabled
        eventChannel = FlutterEventChannel(name: channelName, binaryMessenger: messenger)
        super.init()
        if enabled { eventChannel.setStreamHandler(self) }
    }

    // MARK: FlutterStreamHandler protocol compliance

    func onListen(withArguments _: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        let pending = buffered
        buffered.removeAll()
        for (kind, value) in pending {
            events(value)
            if kind == "success" || kind == "error" { events(FlutterEndOfEventStream) }
        }
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        dispose()
        return nil
    }

    // MARK: Util methods

    func onError(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        emit("error", FlutterError(code: errorCode, message: errorMessage, details: errorDetails))
    }

    func onSuccess() {
        let body = ["status": "success"]
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: body,
            options: .prettyPrinted
        ),
            let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        emit("success", jsonString)
    }

    func onStart() {
        let body = ["status": "start"]
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: body,
            options: .prettyPrinted
        ),
            let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        emit("start", jsonString)
    }

    func onProgress(progress: Double) {
        let body: [String: Any] = ["status": "progress", "progress": progress]
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: body,
            options: .prettyPrinted
        ),
            let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        emit("progress", jsonString)
    }

    private func emit(_ kind: String, _ value: Any) {
        guard enabled, !finished else { return }
        if kind == "success" || kind == "error" { finished = true }
        if let sink = sink {
            sink(value)
            if kind == "success" || kind == "error" { sink(FlutterEndOfEventStream) }
        } else {
            // The method reply creates the region before Dart subscribes.
            // Retain start/terminal events and only the latest progress.
            buffered.removeAll { $0.0 == kind }
            buffered.append((kind, value))
        }
    }

    func dispose() {
        finished = true
        sink?(FlutterEndOfEventStream)
        sink = nil
        buffered.removeAll()
        eventChannel.setStreamHandler(nil)
        let callback = onDisposed
        onDisposed = nil
        callback?()
    }
}
