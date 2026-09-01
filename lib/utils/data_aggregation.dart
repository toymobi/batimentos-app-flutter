import '../models/leitura.dart';
import 'time_period.dart';

/// Ponto agregado para uso nos gráficos.
///
/// Representa um bucket temporal com média, mínimo e máximo
/// de cada métrica, além do número real de leituras no bucket.
class AggregatedPoint {
  final int timestamp;
  final double batimentoAvg;
  final double batimentoMin;
  final double batimentoMax;
  final double respiracaoAvg;
  final double respiracaoMin;
  final double respiracaoMax;
  final double distanciaAvg;
  final int count;

  const AggregatedPoint({
    required this.timestamp,
    required this.batimentoAvg,
    required this.batimentoMin,
    required this.batimentoMax,
    required this.respiracaoAvg,
    required this.respiracaoMin,
    required this.respiracaoMax,
    required this.distanciaAvg,
    required this.count,
  });
}

/// Agrega leituras em buckets temporais para eficiência nos gráficos.
///
/// [leituras] deve estar ordenada por timestamp crescente.
/// [period] determina a resolução dos buckets.
///
/// Retorna a lista de pontos agregados, prontos para uso nos gráficos.
List<AggregatedPoint> agregarLeituras(
  List<Leitura> leituras,
  TimePeriod period,
) {
  if (leituras.isEmpty) return const [];

  // Para 5 minutos, manter alta resolução — sem agregação
  if (period == TimePeriod.fiveMinutes) {
    return leituras
        .map(
          (l) => AggregatedPoint(
            timestamp: l.timestamp,
            batimentoAvg: l.batimento,
            batimentoMin: l.batimento,
            batimentoMax: l.batimento,
            respiracaoAvg: l.respiracao,
            respiracaoMin: l.respiracao,
            respiracaoMax: l.respiracao,
            distanciaAvg: l.distancia,
            count: 1,
          ),
        )
        .toList();
  }

  // Determinar tamanho do bucket em milissegundos
  final bucketMs = _bucketSize(period);

  // Ordenar por timestamp (garantia)
  final sorted = List<Leitura>.from(leituras)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final buckets = <int, List<Leitura>>{};

  for (final l in sorted) {
    // Calcular bucket: arredondar timestamp para o início do intervalo
    final bucketStart =
        (l.timestamp ~/ bucketMs) * bucketMs;
    buckets.putIfAbsent(bucketStart, () => []).add(l);
  }

  return buckets.entries.map((entry) {
    final bucketLeituras = entry.value;
    return _aggregateBucket(entry.key, bucketLeituras);
  }).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}

/// Tamanho do bucket em ms para cada período.
int _bucketSize(TimePeriod period) {
  switch (period) {
    case TimePeriod.fiveMinutes:
      return 5 * 60 * 1000; // não usado (sem agregação)
    case TimePeriod.oneDay:
      return 60 * 1000; // ~1 minuto
    case TimePeriod.oneWeek:
      return 60 * 60 * 1000; // ~1 hora
    case TimePeriod.oneMonth:
      return 24 * 60 * 60 * 1000; // ~1 dia
  }
}

/// Agrega um bucket individual calculando avg/min/max.
AggregatedPoint _aggregateBucket(int bucketStart, List<Leitura> leituras) {
  final batimentos =
      leituras.map((l) => l.batimento).where((v) => v > 0).toList();
  final respiracoes =
      leituras.map((l) => l.respiracao).where((v) => v > 0).toList();
  final distancias =
      leituras.map((l) => l.distancia).where((v) => v > 0).toList();

  return AggregatedPoint(
    timestamp: bucketStart,
    batimentoAvg: _avg(batimentos),
    batimentoMin: _min(batimentos),
    batimentoMax: _max(batimentos),
    respiracaoAvg: _avg(respiracoes),
    respiracaoMin: _min(respiracoes),
    respiracaoMax: _max(respiracoes),
    distanciaAvg: _avg(distancias),
    count: leituras.length,
  );
}

double _avg(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.fold(0.0, (a, b) => a + b) / values.length;
}

double _min(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a < b ? a : b);
}

double _max(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a > b ? a : b);
}
