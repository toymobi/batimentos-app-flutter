import 'leitura.dart';

/// Estatísticas calculadas a partir de uma lista de leituras.
///
/// Todos os cálculos são feitos localmente, sem queries ao Firebase.
/// Leituras com valores inválidos (<= 0) são ignoradas nos cálculos.
class LeituraStatistics {
  final double averageBatimento;
  final double minBatimento;
  final double maxBatimento;

  final double averageRespiracao;
  final double minRespiracao;
  final double maxRespiracao;

  final double averageDistancia;
  final double minDistancia;
  final double maxDistancia;

  final int totalLeituras;
  final int primeiraLeitura;
  final int ultimaLeitura;

  const LeituraStatistics({
    required this.averageBatimento,
    required this.minBatimento,
    required this.maxBatimento,
    required this.averageRespiracao,
    required this.minRespiracao,
    required this.maxRespiracao,
    required this.averageDistancia,
    required this.minDistancia,
    required this.maxDistancia,
    required this.totalLeituras,
    required this.primeiraLeitura,
    required this.ultimaLeitura,
  });

  /// Calcula estatísticas a partir de uma lista de leituras.
  ///
  /// Leituras com timestamp <= 0 ou valores <= 0 para uma métrica
  /// são ignorados nessa métrica específica.
  /// Se nenhuma leitura válida existir, os valores retornam 0.0.
  factory LeituraStatistics.fromLeituras(List<Leitura> leituras) {
    if (leituras.isEmpty) {
      return const LeituraStatistics(
        averageBatimento: 0,
        minBatimento: 0,
        maxBatimento: 0,
        averageRespiracao: 0,
        minRespiracao: 0,
        maxRespiracao: 0,
        averageDistancia: 0,
        minDistancia: 0,
        maxDistancia: 0,
        totalLeituras: 0,
        primeiraLeitura: 0,
        ultimaLeitura: 0,
      );
    }

    // Leituras com timestamp válido para range temporal
    final leiturasComTimestamp =
        leituras.where((l) => l.timestamp > 0).toList();

    // Valores válidos por métrica (>= 0 para não descartar 0.0 do sensor)
    final batimentos =
        leituras.map((l) => l.batimento).where((v) => v > 0).toList();
    final respiracoes =
        leituras.map((l) => l.respiracao).where((v) => v > 0).toList();
    final distancias =
        leituras.map((l) => l.distancia).where((v) => v > 0).toList();

    return LeituraStatistics(
      averageBatimento: _average(batimentos),
      minBatimento: _min(batimentos),
      maxBatimento: _max(batimentos),
      averageRespiracao: _average(respiracoes),
      minRespiracao: _min(respiracoes),
      maxRespiracao: _max(respiracoes),
      averageDistancia: _average(distancias),
      minDistancia: _min(distancias),
      maxDistancia: _max(distancias),
      totalLeituras: leituras.length,
      primeiraLeitura: leiturasComTimestamp.isNotEmpty
          ? leiturasComTimestamp.first.timestamp
          : 0,
      ultimaLeitura: leiturasComTimestamp.isNotEmpty
          ? leiturasComTimestamp.last.timestamp
          : 0,
    );
  }

  static double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold(0.0, (a, b) => a + b);
    return sum / values.length;
  }

  static double _min(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  static double _max(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a > b ? a : b);
  }
}
