
import 'package:pro_tocol/model/entities/TempSessionConfig.dart';
import 'package:pro_tocol/model/services/SSHService.dart';


class TempSession {
  final TempSessionConfig config;
  final SSHService sshService = SSHService();

  TempSession({required this.config});

}