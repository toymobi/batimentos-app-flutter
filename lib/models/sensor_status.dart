/// Estado técnico de conectividade do sensor.
///
/// NÃO é estado médico — é apenas indicador de se o ESP32
/// está a enviar dados ou não.
enum SensorStatus {
  /// Nenhuma leitura recebida ainda.
  unknown,

  /// Última leitura há menos de 30 segundos.
  active,

  /// Última leitura entre 30 segundos e 2 minutos.
  stale,

  /// Última leitura há mais de 2 minutos.
  offline,
}

/// Calcula o estado do sensor com base na idade da última leitura.
///
/// [timestamp] é o timestamp em millis da última leitura recebida.
/// Retorna [SensorStatus.unknown] se o timestamp for inválido (<= 0).
SensorStatus calcularSensorStatus(int timestamp) {
  if (timestamp <= 0) return SensorStatus.unknown;

  final agora = DateTime.now();
  final leitura = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final idade = agora.difference(leitura);

  if (idade.inSeconds < 30) return SensorStatus.active;
  if (idade.inSeconds < 120) return SensorStatus.stale;
  return SensorStatus.offline;
}

/// Formata a idade da última leitura em formato relativo legível.
///
/// Exemplos: "agora", "há 8 segundos", "há 2 minutos", "há 3 horas".
/// Retorna "–" se o timestamp for inválido.
String formatarIdadeLeitura(int timestamp) {
  if (timestamp <= 0) return '–';

  final agora = DateTime.now();
  final leitura = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final idade = agora.difference(leitura);

  if (idade.inSeconds < 5) return 'agora';
  if (idade.inSeconds < 60) return 'há ${idade.inSeconds} segundos';
  if (idade.inMinutes == 1) return 'há 1 minuto';
  if (idade.inMinutes < 60) return 'há ${idade.inMinutes} minutos';
  if (idade.inHours == 1) return 'há 1 hora';
  return 'há ${idade.inHours} horas';
}
