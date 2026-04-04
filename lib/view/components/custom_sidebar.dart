import 'package:flutter/material.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

import '../theme/AppColors.dart';

class CustomSidebar extends StatelessWidget {
  final List<ServerConfig> servers;
  final List<ServerConfig> tempSessions;

  final ServerConfig? activeServer;
  final ServerConfig? activeTempSession;

  // Callbacks para Servidores Isar
  final VoidCallback onAddServer;
  final Function(ServerConfig) onSelectServer;
  final Function(ServerConfig) onEditServer;
  final Function(ServerConfig) onDeleteServer;

  // Callbacks para Sesiones Temporales
  final VoidCallback onAddTempSession;
  final Function(ServerConfig) onSelectTempSession;
  final Function(ServerConfig) onEditTempSession;
  final Function(ServerConfig) onDeleteTempSession;

  const CustomSidebar({
    super.key,
    required this.servers,
    required this.tempSessions,
    this.activeServer,
    this.activeTempSession,
    required this.onAddServer,
    required this.onSelectServer,
    required this.onEditServer,
    required this.onDeleteServer,
    required this.onAddTempSession,
    required this.onSelectTempSession,
    required this.onEditTempSession,
    required this.onDeleteTempSession,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // --- SECCIÓN: SERVIDORES ---
                  _buildSectionHeader('Servidores', Icons.dns_outlined, onAddServer),
                  ...servers.map((server) => _buildItem(
                    title: server.host,
                    subtitle: server.username,
                    hasStatus: true,
                    isActive: activeServer?.id == server.id,
                    onTap: () {
                      Navigator.pop(context); // Cierra el Drawer
                      onSelectServer(server);
                    },
                    onEdit: () {
                      Navigator.pop(context);
                      onEditServer(server);
                    },
                    onDelete: () {
                      Navigator.pop(context);
                      onDeleteServer(server);
                    },
                  )),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // --- SECCIÓN: SESIONES TEMPORALES ---
                  _buildSectionHeader('Sesiones Temporales', Icons.access_time, onAddTempSession),
                  ...tempSessions.map((session) => _buildItem(
                    title: session.host,
                    subtitle: session.username,
                    hasStatus: false,
                    isActive: activeTempSession?.id == session.id,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTempSession(session);
                    },
                    onEdit: () {
                      Navigator.pop(context);
                      onEditTempSession(session);
                    },
                    onDelete: () {
                      Navigator.pop(context);
                      onDeleteTempSession(session);
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Menú', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textMuted, size: 20),
            onPressed: onAdd,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    String? subtitle,
    bool hasStatus = false,
    bool isActive = false,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceHighlight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: hasStatus
            ? CircleAvatar(radius: 4, backgroundColor: isActive ? AppColors.success : Colors.white24)
            : const CircleAvatar(radius: 4, backgroundColor: Colors.transparent), // Espaciador para alinear
        title: Text(title, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textPrimary, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}