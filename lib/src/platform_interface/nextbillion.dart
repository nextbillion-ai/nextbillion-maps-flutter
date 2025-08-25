part of "../../nb_maps_flutter.dart";

/// NextBillion class provides static methods for initializing and configuring
/// the NextBillion Maps SDK.
class NextBillion {
  static MethodChannel _nextBillionChannel =
      MethodChannel("plugins.flutter.io/nextbillion_init");

  get channel => _nextBillionChannel;

  @visibleForTesting
  static setMockMethodChannel(MethodChannel channel) {
    _nextBillionChannel = channel;
  }

  static Future<void> initNextBillion(String accessKey) async {
    Map<String, dynamic> config = {"accessKey": accessKey};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/init_nextbillion", config);
  }

  static Future<void> initNextBillionWithTileServer(String accessKey,WellKnownTileServer server) async {
    Map<String, dynamic> config = {"accessKey": accessKey,"server": server.value};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/init_nextbillion_tile_server", config);
  }

  static Future<String> getAccessKey() async {
    return await _nextBillionChannel.invokeMethod("nextbillion/get_access_key");
  }

  static Future<void> setAccessKey(String accessKey) async {
    Map<String, dynamic> config = {"accessKey": accessKey};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/set_access_key", config);
  }

  static Future<String> getBaseUri() async {
    return await _nextBillionChannel.invokeMethod("nextbillion/get_base_uri");
  }

  static Future<void> setBaseUri(String baseUri) async {
    Map<String, dynamic> config = {"baseUri": baseUri};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/set_base_uri", config);
  }

  static Future<void> setApiKeyHeaderName(String apiKeyHeaderName) async {
    Map<String, dynamic> config = {"apiKeyHeaderName": apiKeyHeaderName};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/set_key_header_name", config);
  }

  static Future<String> getApiKeyHeaderName() async {
    return await _nextBillionChannel
        .invokeMethod("nextbillion/get_key_header_name");
  }

  static Future<String> getNbId() async {
    return await _nextBillionChannel.invokeMethod("nextbillion/get_nb_id");
  }

  static Future<void> setUserId(String id) async {
    Map<String, dynamic> config = {"userId": id};
    return await _nextBillionChannel.invokeMethod(
        "nextbillion/set_user_id", config);
  }

  static Future<String?> getUserId() async {
    return await _nextBillionChannel.invokeMethod("nextbillion/get_user_id");
  }

  /// Get the list of predefined map styles available from the current tile server.
  /// 
  /// This method returns a list of [NbDefaultStyle] objects containing:
  /// - name: The display name of the style
  /// - url: The style URL
  /// - version: The style version number
  /// 
  /// Returns null if the styles cannot be loaded or if there's an error.
  /// 
  /// Note: The available styles depend on the currently configured tile server.
  /// Use [switchWellKnownTileServer] to change tile servers and get different
  /// predefined styles.
  static Future<List<NbDefaultStyle>?> predefinedStyles() async {
    try {
      final result = await _nextBillionChannel.invokeMethod("nextbillion/predefined_styles");
      
      if (result == null) {
        return null;
      }
      
      // Parse the result into List<NbDefaultStyle>
      if (result is List) {
        final parsedStyles = <NbDefaultStyle>[];
        for (int i = 0; i < result.length; i++) {
          final item = result[i];
          
          if (item is Map) {
            try {
              final style = NbDefaultStyle.fromJson(item);
              parsedStyles.add(style);
            } catch (e) {
              throw FormatException('Error parsing item $i: $e');
            }
          } else {
            throw FormatException('Invalid item format in predefined styles list: expected Map<String, dynamic> but got ${item.runtimeType}');
          }
        }

        return parsedStyles;
      } else {
        throw FormatException('Expected List but got ${result.runtimeType}');
      }
    } catch (e) {
      return null;
    }
  }

  /// Switch to a different well-known tile server.
  /// 
  /// This method allows you to switch between different tile server providers
  /// (TomTom or MapTiler) at runtime. After switching, you may need to call
  /// [predefinedStyles] again to get the updated list of available styles
  /// for the new tile server.
  /// 
  /// [server] - The tile server to switch to
  /// 
  /// Returns true if the switch was successful, false otherwise.
  static Future<bool> switchWellKnownTileServer(WellKnownTileServer server) async {
    Map<String, dynamic> config = {"server": server.value};
    return await _nextBillionChannel.invokeMethod("nextbillion/switch_tile_server",config);
  }
}
