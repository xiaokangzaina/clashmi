import '../v2board/v2board_client.dart';

class XboardClient extends V2BoardClient {
  XboardClient({
    required super.baseUrl,
    required super.baseDomains,
    required super.id,
    required super.persistent,
  });

  static bool validateEmail(String? value) =>
      V2BoardClient.validateEmail(value);
  static int getPasswordMinLen() => V2BoardClient.getPasswordMinLen();
}
