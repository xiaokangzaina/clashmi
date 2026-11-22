abstract interface class BoardSessionPersistent {
  void updateLoginAuthData(String id, String account, String authData);
  void updateSubscribeUrl(String id, String account, String subscribeUrl);
  void logout(String id, String account);
  void update(String id, String account, String api, dynamic data);
  dynamic get(String id, String account, String api);
}
