import 'package:flutter/material.dart';
import 'package:pro_tocol/presentation/controllers/NavigationController.dart';
import 'package:pro_tocol/presentation/controllers/SSHOrchestrator.dart';
import 'home_screen.dart';
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/presentation/controllers/ProfileController.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileController controller;
  // 1. Almacenamos el navigationController para usarlo en el estado
  final NavigationController navigationController;
  final SSHOrchestrator sshOrchestrator;

  const ProfileScreen({
    super.key,
    required this.controller,
    required this.navigationController,
    required this.sshOrchestrator
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _addProfile() async {
    if (_nameController.text.isNotEmpty && widget.controller.allProfiles.length < 4) {
      await widget.controller.createProfile(_nameController.text);
      _nameController.clear();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // --- NUEVO: EDITAR PERFIL ---
  Future<void> _editProfile(Profile perfil) async {
    _nameController.text = perfil.profileName; // Precargamos el nombre actual
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFEF7F7),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Nuevo nombre',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () {
                    _nameController.clear();
                    Navigator.pop(context);
                  }, child: const Text('Cancelar', style: TextStyle(color: Colors.grey)))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B63FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        await widget.controller.updateProfileName(perfil, _nameController.text);
                        _nameController.clear();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Guardar'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NUEVO: ELIMINAR PERFIL ---
  void _confirmDeleteProfile(Profile perfil) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151821),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        title: const Text('¿Eliminar Perfil?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que deseas eliminar el perfil "${perfil.profileName}"? Se borrarán todos sus servidores guardados. Esta acción no se puede deshacer.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              await widget.controller.deleteProfile(perfil);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = (MediaQuery.of(context).size.width / 2) - 40;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2430), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  final perfilesExistentes = widget.controller.allProfiles;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿ Quien esta ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Selecciona o crea tu perfil',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            ...perfilesExistentes.map((perfil) => _buildProfileCard(perfil, cardWidth)),

                            if (perfilesExistentes.length < 4)
                              _buildCreateButton(cardWidth),
                          ],
                        ),
                      ),
                    ],
                  );
                }
            ),
          ),
        ),
      ),
    );
  }

  // 2. Método de navegación actualizado (Ahora incluye el botón de opciones)
  Widget _buildProfileCard(Profile perfil, double width) {
    return GestureDetector(
      onTap: () {
        // Marcamos el perfil como activo
        widget.controller.setActiveProfile(perfil);

        // RELEVANTE: Reseteamos la vista al Home antes de entrar
        widget.navigationController.goHome();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              profileName: perfil.profileName,
              profileController: widget.controller, 
              navigationController: widget.navigationController, 
              sshOrchestrator: widget.sshOrchestrator,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: width,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF8B63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B63FF).withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF8B63FF),
                  child: Icon(Icons.person, color: Colors.white, size: 35),
                ),
                const SizedBox(height: 12),
                Text(
                  perfil.profileName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // --- NUEVO: BOTÓN DE OPCIONES (TRES PUNTITOS) EN LA ESQUINA SUPERIOR DERECHA ---
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF1E2230),
              onSelected: (value) {
                if (value == 'edit') {
                  _editProfile(perfil);
                } else if (value == 'delete') {
                  _confirmDeleteProfile(perfil);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Editar', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(double width) {
    return GestureDetector(
      onTap: () => _showCreateProfileDialog(context),
      child: Container(
        width: width,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF282A36).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text('Nuevo perfil', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    _nameController.clear(); // Limpiamos el texto al crear uno nuevo
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFEF7F7),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crear Nuevo Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Nombre del Perfil',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey)))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B63FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _addProfile,
                    child: const Text('Crear'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}