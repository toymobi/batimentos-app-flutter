/// Configuração centralizada do sistema de alertas.
///
/// Todos os valores são CONFIGURÁVEIS e representam LIMITES TÉCNICOS,
/// não diagnósticos médicos.
///
/// Os defaults são apenas valores iniciais de exemplo.
/// Devem ser ajustados conforme necessário.
class AlertSettings {
  /// Batimento cardíaco mínimo aceitável (BPM).
  double heartRateMin;

  /// Batimento cardíaco máximo aceitável (BPM).
  double heartRateMax;

  /// Taxa respiratória mínima aceitável (RPM).
  double respiratoryRateMin;

  /// Taxa respiratória máxima aceitável (RPM).
  double respiratoryRateMax;

  /// Número de leituras consecutivas fora do intervalo necessárias
  /// para gerar um alerta. Evita falsos alertas por valores pontuais.
  int consecutiveReadingsRequired;

  /// Threshold para considerar dados "stale" (sem dados recentes).
  Duration staleThreshold;

  /// Threshold para considerar sensor "offline".
  Duration offlineThreshold;

  AlertSettings({
    this.heartRateMin = 50,
    this.heartRateMax = 110,
    this.respiratoryRateMin = 8,
    this.respiratoryRateMax = 25,
    this.consecutiveReadingsRequired = 3,
    this.staleThreshold = const Duration(seconds: 30),
    this.offlineThreshold = const Duration(minutes: 2),
  });

  /// Cria uma cópia com campos opcionalmente alterados.
  AlertSettings copyWith({
    double? heartRateMin,
    double? heartRateMax,
    double? respiratoryRateMin,
    double? respiratoryRateMax,
    int? consecutiveReadingsRequired,
    Duration? staleThreshold,
    Duration? offlineThreshold,
  }) {
    return AlertSettings(
      heartRateMin: heartRateMin ?? this.heartRateMin,
      heartRateMax: heartRateMax ?? this.heartRateMax,
      respiratoryRateMin: respiratoryRateMin ?? this.respiratoryRateMin,
      respiratoryRateMax: respiratoryRateMax ?? this.respiratoryRateMax,
      consecutiveReadingsRequired:
          consecutiveReadingsRequired ?? this.consecutiveReadingsRequired,
      staleThreshold: staleThreshold ?? this.staleThreshold,
      offlineThreshold: offlineThreshold ?? this.offlineThreshold,
    );
  }
}
