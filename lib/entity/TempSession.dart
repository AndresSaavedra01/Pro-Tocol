

import 'package:pro_tocol/entity/GeneralConfig.dart';

class TempSession implements GeneralConfig {
  @override
  final String host;
  @override
  final String username;
  @override
  final int port;
  @override
  final String? password;
  @override
  final String? privateKey;

  TempSession({
    required this.host,
    required this.username,
    this.port = 22,
    required this.password,
    this.privateKey
  });
}