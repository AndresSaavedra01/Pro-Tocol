import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String profileName;

  const HomeScreen({super.key, required this.profileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      
      drawer: _buildSidebar(context),
      
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2430),
        elevation: 0,
        title: const Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white), 
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context), 
          )
        ],
      ),

      
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2430), Color(0xFF000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF282A36),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFF8B63FF),
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Perfil: $profileName', // Mostramos el nombre dinámico aquí
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Usa el menú lateral para gestionar\nservidores y sesiones',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F1319),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B63FF),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F1319),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del Menú
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Menú', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context), // Cierra el sidebar
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // SECCIÓN 1: SERVIDORES
            _buildSectionHeader('Servidores', Icons.dns_outlined, () {
              // Lógica para agregar servidor 
            }),
            _buildSidebarItem('Servidor Principal', true, false, 'Activo'),
            _buildSidebarItem('Servidor Dev', false, false, 'Inactivo'),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, height: 1),

            // SECCIÓN 2: SESIONES TEMPORALES
            _buildSectionHeader('Sesiones Temporales', Icons.access_time, () {
              // Lógica para agregar sesión 
            }),
            _buildSidebarItem('Sesión de Prueba', true, true, '2h 30m'),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white54, size: 20),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  // Ítem de la lista (Servidor o Sesión) con botón de eliminar
  Widget _buildSidebarItem(String title, bool isActive, bool isSession, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF282A36) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: isSession 
              ? null 
              : CircleAvatar(radius: 4, backgroundColor: isActive ? Colors.greenAccent : Colors.white24),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: isSession || !isActive ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () {
              // Aquí irá la lógica para eliminar/cerrar conexión
            },
          ),
        ),
      ),
    );
  }
}