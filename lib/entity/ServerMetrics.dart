
class ServerMetrics {
  final double cpuUsage;      // Porcentaje (0.0 a 100.0)
  final double ramUsedMB;     // Megabytes usados
  final double ramTotalMB;    // Megabytes totales
  final String uptime;        // Tiempo encendido (ej: "2 days, 4 hours")
  final DateTime timestamp;   // Cuándo se tomó la métrica

  ServerMetrics({
    required this.cpuUsage,
    required this.ramUsedMB,
    required this.ramTotalMB,
    required this.uptime,
  }) : timestamp = DateTime.now();

  double get ramPercentage => (ramUsedMB / ramTotalMB) * 100;
}