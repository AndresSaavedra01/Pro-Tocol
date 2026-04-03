
import 'package:isar/isar.dart';
import 'package:pro_tocol/model/daos/ProfileDAO.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

class ProfileRepository {
  final ProfileDAO _profileDAO;

  ProfileRepository(this._profileDAO);

  Future<void> saveProfile(Profile profile) async {
    await _profileDAO.saveProfile(profile);
  }

  Future<List<Profile>> getAllProfiles() async {
    return await _profileDAO.getAllProfiles();
  }

  Future<Profile?> getProfileById(Id id) async {
    return await _profileDAO.getProfileById(id);
  }

  Future<bool> deleteProfile(Id id) async {
    return await _profileDAO.deleteProfile(id);
  }

  Future<void> addServerToProfile(Id profileId, ServerConfig server) async {
    await _profileDAO.addServerToProfile(profileId, server);
  }
}