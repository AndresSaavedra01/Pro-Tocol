
class ServerMetrics {
  final double cpuUsage;
  final int usedRam;
  final int totalRam;
  final String diskUsage;
  final DateTime timestamp;

  ServerMetrics({
    required this.cpuUsage,
    required this.usedRam,
    required this.totalRam,
    required this.diskUsage,
    required this.timestamp,
  });

  // Factory para procesar el texto plano que devuelve Linux
  factory ServerMetrics.fromRawOutput(String raw) {
    final lines = raw.split('\n');
    // Lógica de parsing basada en los comandos de 'fetchMetrics'
    return ServerMetrics(
      cpuUsage: double.tryParse(lines[0]) ?? 0.0,
      usedRam: int.tryParse(lines[1].split(' ')[0]) ?? 0,
      totalRam: int.tryParse(lines[1].split(' ')[1]) ?? 0,
      diskUsage: lines[2].trim(),
      timestamp: DateTime.now(),
    );
  }
}