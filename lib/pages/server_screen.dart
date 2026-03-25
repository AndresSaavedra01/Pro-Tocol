import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pro_tocol/presentation/controllers/SSHOrchestrator.dart';
import 'package:pro_tocol/entity/SSHService.dart';
import '../entity/FileNode.dart';
import '../entity/ServerMetrics.dart';

class ServerScreen extends StatefulWidget {
  final String serverName;
  final String connectionInfo;
  final bool isTemporarySession;
  final SSHOrchestrator orchestrator;

  const ServerScreen({
    super.key,
    required this.serverName,
    required this.connectionInfo,
    required this.isTemporarySession,
    required this.orchestrator,
  });

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  late final Terminal terminal;
  SSHService? _currentService;
  Timer? _metricsTimer;

  // --- VARIABLES DE ESTADO ---
  String currentPath = "/";
  List<FlSpot> cpuPoints = [const FlSpot(0, 0)];
  List<FlSpot> ramPoints = [const FlSpot(0, 0)];
  List<FileNode> currentFiles = [];
  bool _isLoadingFiles = false;
  List<FlSpot> diskPoints = [const FlSpot(0, 0)];
  String _rawDiskInfo = "0%";
  int _totalRamMb = 0;
  int _usedRamMb = 0;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 10000);
    _connectToOrchestrator();
  }

  @override
  void dispose() {
    _metricsTimer?.cancel(); // IMPORTANTE: Detener el Timer al salir
    super.dispose();
  }

  Future<void> _connectToOrchestrator() async {
    _currentService = widget.orchestrator.getService(widget.connectionInfo);

    if (_currentService == null || !_currentService!.isConnected) {
      terminal.write('\x1B[31mError: No hay conexión activa en el orquestador.\x1B[0m\r\n');
      return;
    }

    try {
      final session = await _currentService!.createTerminal();

      session.stdout.listen((data) {
        terminal.write(utf8.decode(data));
      });

      terminal.onOutput = (input) {
        session.stdin.add(utf8.encode(input));
      };

      terminal.write('\x1B[32mConectado a la terminal activa.\x1B[0m\r\n\n');

      // Iniciar servicios paralelos
      _refreshFiles();
      if (!widget.isTemporarySession) {
        _listenToSystemStats();
      }
    } catch (e) {
      terminal.write('\x1B[31mError al sincronizar consola: $e\x1B[0m\r\n');
    }
  }

  // --- LÓGICA DE MÉTRICAS REALES ---
  void _listenToSystemStats() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        if (_currentService != null && _currentService!.isConnected) {
          final metrics = await _currentService!.fetchMetrics();

          if (mounted) {
            setState(() {
              double x = cpuPoints.length.toDouble();

              // CPU
              cpuPoints.add(FlSpot(x, metrics.cpuUsage));

              // RAM (Guardamos valores reales para las etiquetas)
              _totalRamMb = metrics.totalRam;
              _usedRamMb = metrics.usedRam;
              double ramPercent = (_usedRamMb / _totalRamMb) * 100;
              ramPoints.add(FlSpot(x, ramPercent));

              // DISCO: Limpiamos el "%" del string (ej: "45%" -> 45.0)
              _rawDiskInfo = metrics.diskUsage;
              double diskVal = double.tryParse(_rawDiskInfo.replaceAll('%', '')) ?? 0;
              diskPoints.add(FlSpot(x, diskVal));

              // Limpieza de historial (mantener 15 puntos)
              if (cpuPoints.length > 15) {
                cpuPoints.removeAt(0);
                ramPoints.removeAt(0);
                diskPoints.removeAt(0);
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Error en métricas: $e");
      }
    });
  }

  // --- LÓGICA DE SFTP REAL ---
  Future<void> _refreshFiles() async {
    if (_currentService?.sftp == null) return;

    setState(() => _isLoadingFiles = true);
    try {
      final files = await _currentService!.sftp!.listDirectory(currentPath);
      if (mounted) {
        setState(() {
          currentFiles = files;
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFiles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error SFTP: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1319),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B2430),
          title: Column(
            children: [
              Text(widget.serverName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.connectionInfo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          centerTitle: true,
          bottom: widget.isTemporarySession
              ? null
              : const TabBar(
            indicatorColor: Color(0xFF8B63FF),
            labelColor: Colors.white,
            tabs: [Tab(text: 'Estado'), Tab(text: 'Terminal'), Tab(text: 'Archivos')],
          ),
        ),
        body: widget.isTemporarySession
            ? _buildTerminalTab()
            : TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildEstadoTab(),
            _buildTerminalTab(),
            _buildArchivosTab(),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildEstadoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // GRÁFICO CPU + ESTADÍSTICA
          _buildGraphContainer("Uso de CPU", Colors.blue, cpuPoints),
          _buildDetailLabel("Carga actual: ${cpuPoints.last.y.toStringAsFixed(1)}%"),

          const SizedBox(height: 25),

          // GRÁFICO RAM + ESTADÍSTICA (MB Reales)
          _buildGraphContainer("Uso de RAM", Colors.purple, ramPoints),
          _buildDetailLabel("Memoria: $_usedRamMb MB / $_totalRamMb MB"),

          const SizedBox(height: 25),

          // NUEVO: GRÁFICO DE DISCO (Almacenamiento)
          _buildGraphContainer("Almacenamiento (Raíz /)", Colors.orange, diskPoints),
          _buildDetailLabel("Ocupado: $_rawDiskInfo del total"),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

// Widget auxiliar para las etiquetas de texto debajo de los gráficos
  Widget _buildDetailLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, left: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }


  Widget _buildArchivosTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          color: const Color(0xFF1B2430),
          child: Row(
            children: [
              // BOTÓN DE RETROCEDER (CD ..)
              if (currentPath != "/")
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Color(0xFF8B63FF), size: 20),
                  onPressed: _goBack,
                  tooltip: "Subir un nivel",
                ),
              const Icon(Icons.folder_open, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currentPath,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingFiles)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFiles,
            child: ListView.builder(
              itemCount: currentFiles.length,
              itemBuilder: (context, index) => _buildFileNodeItem(currentFiles[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileNodeItem(FileNode node) {
    return ListTile(
      leading: Icon(
        node.isDirectory ? Icons.folder : Icons.insert_drive_file,
        color: node.isDirectory ? const Color(0xFF8B63FF) : Colors.white54,
      ),
      title: Text(node.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text("${node.permissions} • ${_formatSize(node.sizeInBytes)}",
          style: const TextStyle(color: Colors.white24, fontSize: 11)),
      onTap: () {
        if (node.isDirectory) {
          // Evitar bucles de navegación si el nombre es "." o ".."
          if (node.name == ".") return;

          setState(() {
            currentPath = node.path;
          });
          _refreshFiles();
        }
      },
    );
  }

  Widget _buildTerminalTab() {
    return Container(
      color: Colors.black,
      child: TerminalView(
        terminal,
        autofocus: true,
        backgroundOpacity: 1,
        textStyle: const TerminalStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildGraphContainer(String title, Color col, List<FlSpot> points) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100, // Gráficos basados en porcentaje
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    color: col,
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: col.withOpacity(0.1)),
                  )
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _goBack() {
    if (currentPath == "/" || currentPath == "") return;

    // Dividimos la ruta por "/"
    List<String> parts = currentPath.split('/');

    // Eliminamos el último segmento (si termina en / las partes vacías se manejan)
    if (parts.last.isEmpty) parts.removeLast();
    if (parts.isNotEmpty) parts.removeLast();

    // Reconstruimos la ruta
    String newPath = parts.join('/');

    // Si queda vacío, es la raíz
    if (newPath.isEmpty) newPath = "/";

    setState(() {
      currentPath = newPath;
    });
    _refreshFiles();
  }
}