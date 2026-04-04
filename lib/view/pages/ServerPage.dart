import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:pro_tocol/controller/ServerController.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/entities/FileNode.dart';
import 'package:pro_tocol/model/entities/ServerModel.dart';

import '../theme/AppColors.dart';

class ServerPage extends StatefulWidget {
  final ServerConfig serverConfig;
  final ServerController serverController;
  final bool isTemporarySession;

  const ServerPage({
    super.key,
    required this.serverConfig,
    required this.serverController,
    this.isTemporarySession = false,
  });

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late final Terminal terminal;
  ServerModel? _activeServer;
  Timer? _metricsTimer;

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
    _connectToServerController();
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }

  Future<void> _connectToServerController() async {
    try {
      _activeServer = widget.serverController.getActiveServer(widget.serverConfig.id);
      final session = await _activeServer!.sshService.createTerminal();

      session.stdout.listen((data) {
        if (mounted) terminal.write(utf8.decode(data));
      });

      session.stderr.listen((data) {
        if (mounted) terminal.write(utf8.decode(data));
      });

      terminal.onOutput = (input) {
        session.stdin.add(utf8.encode(input));
      };

      terminal.write('\x1B[32mConectado a la terminal activa de ${widget.serverConfig.host}.\x1B[0m\r\n\n');

      _refreshFiles();
      if (!widget.isTemporarySession) {
        _listenToSystemStats();
      }
    } catch (e) {
      if (mounted) terminal.write('\x1B[31mError al sincronizar consola: $e\x1B[0m\r\n');
    }
  }

  void _listenToSystemStats() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        if (_activeServer != null && _activeServer!.sshService.isConnected) {
          final metrics = await _activeServer!.sshService.fetchMetrics();
          if (mounted) {
            setState(() {
              double x = cpuPoints.length.toDouble();
              cpuPoints.add(FlSpot(x, metrics.cpuUsage));
              _totalRamMb = metrics.totalRam;
              _usedRamMb = metrics.usedRam;
              double ramPercent = (_usedRamMb / _totalRamMb) * 100;
              ramPoints.add(FlSpot(x, ramPercent));
              _rawDiskInfo = metrics.diskUsage;
              double diskVal = double.tryParse(_rawDiskInfo.replaceAll('%', '')) ?? 0;
              diskPoints.add(FlSpot(x, diskVal));

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

  Future<void> _refreshFiles() async {
    if (_activeServer?.sshService.sftp == null) return;

    setState(() => _isLoadingFiles = true);
    try {
      final files = await _activeServer!.sshService.sftp!.listDirectory(currentPath);
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
          SnackBar(content: Text("Error SFTP: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionString = "${widget.serverConfig.username}@${widget.serverConfig.host}";

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Column(
            children: [
              Text(
                  widget.isTemporarySession ? 'Sesión Temporal' : widget.serverConfig.host,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              Text(connectionString, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          centerTitle: true,
          bottom: widget.isTemporarySession
              ? null
              : const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
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

  Widget _buildEstadoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildGraphContainer("Uso de CPU", Colors.blue, cpuPoints),
          _buildDetailLabel("Carga actual: ${cpuPoints.last.y.toStringAsFixed(1)}%"),
          const SizedBox(height: 25),

          _buildGraphContainer("Uso de RAM", Colors.purple, ramPoints),
          _buildDetailLabel("Memoria: $_usedRamMb MB / $_totalRamMb MB"),
          const SizedBox(height: 25),

          _buildGraphContainer("Almacenamiento (Raíz /)", Colors.orange, diskPoints),
          _buildDetailLabel("Ocupado: $_rawDiskInfo del total"),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDetailLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, left: 8),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildArchivosTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: Row(
            children: [
              if (currentPath != "/")
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: AppColors.primary, size: 20),
                    onPressed: _goBack,
                    tooltip: "Subir un nivel",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              const Icon(Icons.folder_open, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPath,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingFiles)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
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
    final isDir = node.isDirectory;
    IconData nodeIcon = Icons.insert_drive_file;
    Color iconColor = AppColors.textMuted;

    if (isDir) {
      nodeIcon = Icons.folder;
      iconColor = AppColors.fileDir;
    } else if (node.type == FileType.txt || node.type == FileType.markdown) {
      nodeIcon = Icons.description;
      iconColor = AppColors.fileTxt;
    } else if (node.type == FileType.image) {
      nodeIcon = Icons.image;
      iconColor = AppColors.fileImg;
    } else if (node.type == FileType.config) {
      nodeIcon = Icons.settings;
      iconColor = AppColors.fileCfg;
    }

    return ListTile(
      leading: Icon(nodeIcon, color: iconColor),
      title: Text(node.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      subtitle: Text("${node.permissions} • ${_formatSize(node.sizeInBytes)}",
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      trailing: isDir ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20) : null,
      onTap: () {
        if (node.isDirectory) {
          if (node.name == ".") return;
          setState(() {
            currentPath = node.path;
          });
          _refreshFiles();
        } else {
          debugPrint("Tocaste el archivo: ${node.name}");
        }
      },
    );
  }

  Widget _buildTerminalTab() {
    return Container(
      color: AppColors.terminalBg,
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TerminalView(
            terminal,
            autofocus: true,
            backgroundOpacity: 1,
            theme: TerminalTheme(
              cursor: AppColors.textPrimary,
              selection: Colors.blueAccent.withOpacity(0.4),
              foreground: AppColors.textPrimary,
              background: AppColors.background, // Usa el fondo base oscuro
              black: Colors.black,
              red: AppColors.error,
              green: AppColors.success,
              yellow: Colors.yellowAccent,
              blue: Colors.blueAccent,
              magenta: Colors.purpleAccent,
              cyan: Colors.cyanAccent,
              white: AppColors.textPrimary,
              brightBlack: Colors.grey,
              brightRed: Colors.red,
              brightGreen: Colors.green,
              brightYellow: Colors.yellow,
              brightBlue: Colors.blue,
              brightMagenta: Colors.purple,
              brightCyan: Colors.cyan,
              brightWhite: Colors.white,
              searchHitBackground: Colors.yellowAccent.withOpacity(0.3),
              searchHitBackgroundCurrent: Colors.orangeAccent.withOpacity(0.5),
              searchHitForeground: Colors.black,
            ),
            textStyle: const TerminalStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphContainer(String title, Color col, List<FlSpot> points) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard.copyWith(
          color: AppColors.surface // Un poco más oscuro que el highlight
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
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
    List<String> parts = currentPath.split('/');
    if (parts.last.isEmpty) parts.removeLast();
    if (parts.isNotEmpty) parts.removeLast();
    String newPath = parts.join('/');
    if (newPath.isEmpty) newPath = "/";
    setState(() => currentPath = newPath);
    _refreshFiles();
  }
}