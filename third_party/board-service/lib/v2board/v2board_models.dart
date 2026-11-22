class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;
}

class SubscribeInfo {
  const SubscribeInfo(this.subscribeUrl);

  final String subscribeUrl;
}
