import 'package:flutter/material.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import '../../controller/ProfileController.dart';
import '../../controller/ServerController.dart';
import '../layouts/WorkspaceLayout.dart';

class ProfilesPage extends StatefulWidget {
  final ProfileController profileController;
  final ServerController serverController;

  const ProfilesPage({
    Key? key,
    required this.profileController,
    required this.serverController,
  }) : super(key: key);

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await widget.profileController.loadAllProfiles();
      setState(() => _profiles = profiles);
    } catch (e) {
      _showSnackBar('Error cargando perfiles: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Muestra un modal para Crear o Editar un perfil
  Future<void> _showProfileDialog({Profile? profile}) async {
    final isEditing = profile != null;
    final nameController = TextEditingController(text: isEditing ? profile.profileName : '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Perfil' : 'Nuevo Perfil'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del perfil',
                hintText: 'Ej. Servidores Producción',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Debe tener al menos 3 caracteres';
                }
                return null;
              },
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context); // Cierra el dialog
                  await _saveProfile(nameController.text, profileToEdit: profile);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Lógica para guardar o actualizar y refrescar la UI
  Future<void> _saveProfile(String name, {Profile? profileToEdit}) async {
    try {
      if (profileToEdit == null) {
        // CREAR
        await widget.profileController.createProfile(name);
        _showSnackBar('Perfil creado con éxito');
      } else {
        // ACTUALIZAR (Asegúrate de tener este método en tu ProfileController)
        profileToEdit.profileName = name.trim();
        await widget.profileController.updateProfile(profileToEdit);
        _showSnackBar('Perfil actualizado');
      }
      _loadProfiles(); // Refrescamos la lista
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  /// Lógica de eliminación con confirmación
  Future<void> _confirmDelete(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Perfil'),
        content: Text('¿Estás seguro de eliminar "${profile.profileName}" y todos sus servidores? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.profileController.deleteProfile(profile.id);
        _showSnackBar('Perfil eliminado');
        _loadProfiles();
      } catch (e) {
        _showSnackBar('Error al eliminar: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Perfiles SSH')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? _buildEmptyState()
          : _buildProfileList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProfileDialog(),
        tooltip: 'Crear Perfil',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.folder_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tienes perfiles todavía.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona el botón + para comenzar.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.folder_shared),
            ),
            title: Text(profile.profileName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${profile.servers.length} servidores configurados'),
            onTap: () {
              // Navegar al Workspace Layout
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkspaceLayout(
                    profile: profile,
                    serverController: widget.serverController,
                  ),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  tooltip: 'Editar',
                  onPressed: () => _showProfileDialog(profile: profile),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar',
                  onPressed: () => _confirmDelete(profile),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}