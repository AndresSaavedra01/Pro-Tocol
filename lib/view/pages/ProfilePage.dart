import 'package:flutter/material.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/controller/ProfileController.dart';
import 'package:pro_tocol/controller/ServerController.dart';

import '../theme/AppColors.dart';
import 'WorkspacePage.dart';

class ProfilePage extends StatefulWidget {
  final ProfileController profileController;
  final ServerController serverController;

  const ProfilePage({
    super.key,
    required this.profileController,
    required this.serverController,
  });

  @override
  State<ProfilePage> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();

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
      debugPrint('Error cargando perfiles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProfile() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && _profiles.length < 4) {
      await widget.profileController.createProfile(name);
      _nameController.clear();

      if (mounted) Navigator.pop(context);
      await _loadProfiles();
    }
  }

  Future<void> _editProfile(Profile perfil) async {
    _nameController.text = perfil.profileName;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.dialogLight,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: AppTheme.lightInputDecoration('Nuevo nombre'),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () {
                            _nameController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
                      )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          final newName = _nameController.text.trim();
                          if (newName.isNotEmpty) {
                            perfil.profileName = newName;
                            await widget.profileController.updateProfile(perfil);

                            _nameController.clear();
                            if (context.mounted) Navigator.pop(context);

                            await _loadProfiles();
                          }
                        },
                        child: const Text('Guardar'),
                      )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProfile(Profile perfil) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: const Text('¿Eliminar Perfil?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que deseas eliminar el perfil "${perfil.profileName}"? Se borrarán todos sus servidores guardados. Esta acción no se puede deshacer.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await widget.profileController.deleteProfile(perfil.id);
              await _loadProfiles();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
        decoration: AppTheme.mainBackground,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Quién está?', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Selecciona o crea tu perfil', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._profiles.map((perfil) => _buildProfileCard(perfil, cardWidth)),
                      if (_profiles.length < 4) _buildCreateButton(cardWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Profile perfil, double width) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => WorkspacePage(
              profile: perfil,
              profileController: widget.profileController,
              serverController: widget.serverController,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1), // Sube solo un 10% de la pantalla
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: width,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: AppColors.textPrimary, size: 35),
                ),
                const SizedBox(height: 12),
                Text(
                  perfil.profileName,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              color: AppColors.surfaceHighlight,
              onSelected: (value) {
                if (value == 'edit') _editProfile(perfil);
                else if (value == 'delete') _confirmDeleteProfile(perfil);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
                      SizedBox(width: 8),
                      Text('Editar', style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: AppColors.error)),
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
        decoration: AppTheme.glassCard.copyWith(
            color: AppColors.surfaceHighlight.withOpacity(0.5)
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.textMuted, size: 48),
            SizedBox(height: 8),
            Text('Nuevo perfil', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.dialogLight,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crear Nuevo Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: AppTheme.lightInputDecoration('Nombre del Perfil'),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
                      )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _addProfile,
                        child: const Text('Crear'),
                      )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}