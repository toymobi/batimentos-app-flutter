/// Períodos temporais disponíveis para filtrar gráficos e estatísticas.
///
/// Cada período define a duração para trás a considerar a partir de "agora".
enum TimePeriod {
  fiveMinutes(Duration(minutes: 5), '5 min'),
  oneDay(Duration(days: 1), 'Dia'),
  oneWeek(Duration(days: 7), 'Semana'),
  oneMonth(Duration(days: 30), 'Mês');

  /// Duração para trás a partir de agora.
  final Duration duration;

  /// Label curto para o botão do seletor.
  final String label;

  const TimePeriod(this.duration, this.label);

  /// Retorna o timestamp de início (em millis) para este período.
  int get startTimestamp =>
      DateTime.now().subtract(duration).millisecondsSinceEpoch;

  /// Retorna o timestamp de fim (em millis) — agora.
  int get endTimestamp => DateTime.now().millisecondsSinceEpoch;
}
