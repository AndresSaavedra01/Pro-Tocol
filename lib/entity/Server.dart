
import 'package:pro_tocol/entity/BaseConnection.dart';

class server extends Baseconnection {

  String alias;
  server({
    required this.alias,
    required String user,
    required String ip,
    required String pass
  }) : super(ip, user, pass) {
    saveInDataBase();
  }

  void saveInDataBase() {
    print("Guardando $alias en la memoria local...");
  }

}

