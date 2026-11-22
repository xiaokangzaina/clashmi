import 'dart:convert';
import 'package:tuple/tuple.dart';

String _json(Map<String, dynamic> value) => jsonEncode(value);
Tuple3<String, String, String> _endpoint(String path, Map<String, dynamic> body) {
  const base = 'https://api.clashmi.app';
  return Tuple3('$base$path', '', _json(body));
}

abstract final class AppUrlUtilsPrivate {
  static String signQueryParams(String version, String bodyLen, Map<String, dynamic> params) {
    return Uri(queryParameters: {'v': version, 'l': bodyLen, ...params.map((key, value) => MapEntry(key, '$value'))}).query;
  }

  static String signQueryParams2(String version, Map<String, dynamic> params, {String bodyLen = '0'}) {
    return Uri(queryParameters: {'v': version, 'l': bodyLen, ...params.map((key, value) => MapEntry(key, '$value'))}).query;
  }

  static Future<Map<String, List<String>>> parseLifeline(String app, String value) async {
    if (value.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, item) => MapEntry(key.toString(), (item is List ? item : [item]).map((e) => e.toString()).toList()));
      }
    } catch (_) {}
    return {};
  }
}

abstract final class BoardProviderPrivate {
  static Tuple3<String, String, String> getBycodeUrlAndBody({required String app, required String version, required String did, required String code}) => _endpoint('/v1/provider/by-code', {'app': app, 'version': version, 'did': did, 'code': code});
  static Tuple3<String, String, String> getNotifyIntegrationUrlAndBody({required String app, required String version, required String did, required String url, required String type}) => _endpoint('/v1/provider/integration', {'app': app, 'version': version, 'did': did, 'url': url, 'type': type});
  static Tuple3<String, String, String> getNoticePushUrlAndBody({required String app, required String version, required String did, required String pid}) => _endpoint('/v1/provider/notice', {'app': app, 'version': version, 'did': did, 'pid': pid});
}

abstract final class ProfileProxyProviderPrivate {
  static Tuple3<String, String, String> getProviderProxyUrlAndBody({required String app, required String version, required String did, required String boardProviderId, required String url, required String userAgent, required Map<String, String> xhwidHeaders}) => _endpoint('/v1/provider/proxy', {'app': app, 'version': version, 'did': did, 'provider': boardProviderId, 'url': url, 'user_agent': userAgent, 'xhwid_headers': xhwidHeaders});
}
