import '../src/panel_client.dart';
import 'v2board_models.dart';

class V2BoardClient extends PanelClient {
  V2BoardClient({
    required super.baseUrl,
    required List<String> baseDomains,
    required super.id,
    required super.persistent,
  });

  static bool validateEmail(String? value) => PanelClient.isEmail(value);
  static int getPasswordMinLen() => 8;

  String _apiVersion = 'v1';
  void setVersion(Object? value) {
    _apiVersion = value == 'v2' ? 'v2' : 'v1';
  }

  @override
  Map<String, String> getAuthHeaders() =>
      authToken.isEmpty ? {} : {'authorization': authToken};

  @override
  Map<String, String> getAuthCookies() => {};

  @override
  Map<String, String> getAuthLocalStorage() =>
      authToken.isEmpty ? {} : {'auth_data': authToken};

  Future<BoardResponse<void>> login(LoginRequest login) async {
    setAccount(login.email);
    final reply = await request(
      '/api/$_apiVersion/passport/auth/login',
      authenticated: false,
      form: {'email': login.email, 'password': login.password},
    );
    final data = reply.json['data'];
    final token = data is Map ? data['auth_data'] : null;
    if (reply.status != 200 || token is! String || token.isEmpty) {
      return reply.failure();
    }
    rememberToken(token);
    return const BoardResponse(200);
  }

  Future<BoardResponse<SubscribeInfo>> getSubscribe() async {
    final reply = await request('/api/$_apiVersion/user/getSubscribe');
    final data = reply.json['data'];
    final url = data is Map ? data['subscribe_url'] : null;
    if (reply.status != 200 || url is! String || url.isEmpty) {
      return reply.failure();
    }
    persistent.updateSubscribeUrl(id, account, url);
    return BoardResponse(200, data: SubscribeInfo(url));
  }
}
