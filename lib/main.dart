import 'package:flutter/material.dart';
import 'package:pro_tocol/entity//SSHService.dart';
import 'package:pro_tocol/entity/FileNode.dart';
import 'package:pro_tocol/entity/TempSession.dart';
import 'package:pro_tocol/pages/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Perfiles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B63FF)),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}