import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/repositories/ProfileRepository.dart';

class ProfileController {
  final ProfileRepository _profileRepository;

  ProfileController(this._profileRepository);

  /// [READ] Obtiene todos los perfiles con sus servidores cargados
  Future<List<Profile>> loadAllProfiles() async {
    return await _profileRepository.getAllProfiles();
  }

  /// [CREATE] Crea un nuevo perfil validando el nombre
  Future<Profile> createProfile(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre del perfil no puede estar vacío.');
    }
    if (cleanName.length < 3) {
      throw ArgumentError('El nombre del perfil debe tener al menos 3 caracteres.');
    }

    final newProfile = Profile()..profileName = cleanName;
    await _profileRepository.saveProfile(newProfile);

    return newProfile;
  }

  /// [UPDATE] Actualiza un perfil existente
  Future<void> updateProfile(Profile profile) async {
    final cleanName = profile.profileName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre del perfil no puede estar vacío.');
    }
    if (cleanName.length < 3) {
      throw ArgumentError('El nombre del perfil debe tener al menos 3 caracteres.');
    }

    // Isar funciona como un "upsert": si el ID ya existe, lo sobrescribe (actualiza).
    await _profileRepository.saveProfile(profile);
  }

  /// [DELETE] Elimina un perfil
  Future<bool> deleteProfile(int id) async {
    return await _profileRepository.deleteProfile(id);
  }
}