
import 'package:pro_tocol/entity/BaseConnection.dart';

class Tempsesion extends Baseconnection {

  int id;
  static int count = 0;
  Tempsesion(super.ip, super.user, super.pass) : id = count++;

}