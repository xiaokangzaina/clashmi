import 'dart:convert';
import 'dart:io';

import '../board_session_persistent.dart';

class BoardResponse<T> {
  const BoardResponse(this.statusCode, {this.data, this.message});

  final int statusCode;
  final T? data;
  final String? message;

  bool get ret => statusCode == HttpStatus.ok;

  String getFullMessage() => message ?? 'Panel returned HTTP $statusCode';
}

class PanelReply {
  const PanelReply(this.status, this.body, this.cookies);

  final int status;
  final String body;
  final List<Cookie> cookies;

  Map<String, dynamic> get json {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
    } on FormatException {
      // Some panels return an HTML error page.
    }
    return {};
  }

  BoardResponse<T> failure<T>() {
    final detail = json['message'] ?? json['msg'];
    return BoardResponse<T>(
      status == 200 ? 502 : status,
      message: detail is String ? detail : null,
    );
  }
}

abstract class PanelClient {
  PanelClient({
    required this.baseUrl,
    required this.id,
    required this.persistent,
  });

  String baseUrl;
  final String id;
  final BoardSessionPersistent persistent;
  Duration timeout = const Duration(seconds: 15);
  String? proxyUrl;
  String? userAgent;
  String account = '';
  String authToken = '';
  Map<String, String> _browserHeaders = {};
  List<String> _browserCookies = [];

  static bool isEmail(String? value) =>
      value != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  void setAccount(String value) => account = value;

  void setAuthToken(String value) => authToken = value;

  Map<String, String> getAuthHeaders();
  Map<String, String> getAuthCookies();
  Map<String, String> getAuthLocalStorage();

  void setHeadersAndCookiesForBot(
    Map<String, String> headers,
    List<String> cookies,
  ) {
    _browserHeaders = Map.of(headers);
    _browserCookies = List.of(cookies);
  }

  void rememberToken(String value) {
    authToken = value;
    persistent.updateLoginAuthData(id, account, value);
  }

  Future<void> logout() async {
    authToken = '';
    persistent.logout(id, account);
  }

  Future<PanelReply> request(
    String route, {
    Map<String, String>? form,
    bool authenticated = true,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    if (userAgent?.isNotEmpty == true) client.userAgent = userAgent;
    final proxy = proxyUrl;
    if (proxy != null && proxy.isNotEmpty) {
      client.findProxy = (_) => 'PROXY $proxy';
    }
    try {
      final base = Uri.parse(baseUrl);
      final url = base.resolve(route);
      if (url.scheme != 'https' ||
          url.origin != base.origin ||
          url.userInfo.isNotEmpty) {
        return const PanelReply(400, '{"message":"Invalid panel URL"}', []);
      }
      final request = await client
          .openUrl(form == null ? 'GET' : 'POST', url)
          .timeout(timeout);
      request.followRedirects = false;
      for (final entry in _browserHeaders.entries) {
        if (const [
          'accept',
          'accept-language',
          'user-agent',
        ].contains(entry.key.toLowerCase())) {
          request.headers.set(entry.key, entry.value);
        }
      }
      if (authenticated) {
        for (final entry in getAuthHeaders().entries) {
          request.headers.set(entry.key, entry.value);
        }
        for (final entry in getAuthCookies().entries) {
          request.cookies.add(Cookie(entry.key, entry.value));
        }
      }
      for (final raw in _browserCookies) {
        try {
          request.cookies.add(Cookie.fromSetCookieValue(raw));
        } on FormatException {
          // Omit an invalid cookie exported by the webview.
        }
      }
      if (form != null) {
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        );
        request.write(Uri(queryParameters: form).query);
      }
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return PanelReply(response.statusCode, body, response.cookies);
    } on Exception {
      return const PanelReply(503, '{"message":"Panel request failed"}', []);
    } finally {
      client.close(force: true);
    }
  }
}
