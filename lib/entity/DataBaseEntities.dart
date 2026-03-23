
import 'package:isar/isar.dart';
import 'package:pro_tocol/entity/GeneralConfig.dart';

part 'DataBaseEntities.g.dart';

@Collection()
class Profile {
  Id id = Isar.autoIncrement;

  late String profileName;

  final servers = IsarLinks<ServerConfig>();
}

@Collection()
class ServerConfig implements GeneralConfig {
  Id id = Isar.autoIncrement;

  @override
  late String host;
  @override
  late String username;
  @override
  late int port;
  @override
  String? password;
  @override
  String? privateKey;

  @Backlink(to: 'servers')
  final profile = IsarLink<Profile>();
}