

class Profile {
  String name;
  String avatarPath;
  DateTime createdAt;


  Profile({
  required this.name,
  required this.avatarPath,
  }) : createdAt = DateTime.now();


}