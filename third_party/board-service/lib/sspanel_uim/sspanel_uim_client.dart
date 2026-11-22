import 'dart:convert';

import 'package:tuple/tuple.dart';

import '../src/panel_client.dart';

class SSPanelUimClient extends PanelClient {
  SSPanelUimClient({
    required super.baseUrl,
    required List<String> baseDomains,
    required super.id,
    required super.persistent,
  });

  static bool validateEmail(String? value) => PanelClient.isEmail(value);
  static int getPasswordMinLen() => 6;

  @override
  Map<String, String> getAuthHeaders() => {};

  @override
  Map<String, String> getAuthCookies() {
    if (authToken.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(authToken) as Map);
    } on Exception {
      return {};
    } on TypeError {
      return {};
    }
  }

  @override
  Map<String, String> getAuthLocalStorage() => {};

  Future<BoardResponse<void>> login(String email, String password) async {
    setAccount(email);
    final reply = await request(
      '/auth/login',
      authenticated: false,
      form: {'email': email, 'passwd': password, 'remember_me': 'true'},
    );
    final ret = reply.json['ret'];
    if (reply.status != 200 ||
        (ret != 1 && ret != true) ||
        reply.cookies.isEmpty) {
      return reply.failure();
    }
    rememberToken(
      jsonEncode({
        for (final cookie in reply.cookies) cookie.name: cookie.value,
      }),
    );
    return const BoardResponse(200);
  }

  Future<BoardResponse<Tuple2<String, String>>>
  getUserProfileUrlAndToken() async {
    final reply = await request('/user');
    if (reply.status != 200) return reply.failure();
    final url = RegExp(r'https?://[^\s"<>]+/(?:sub|link)/[^\s"<>]+')
        .allMatches(reply.body)
        .map((match) => match.group(0)!.replaceAll('&amp;', '&'))
        .firstOrNull;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.pathSegments.isEmpty) {
      return reply.failure();
    }
    persistent.updateSubscribeUrl(id, account, url!);
    return BoardResponse(200, data: Tuple2(url, uri.pathSegments.last));
  }
}
