class Leitura {
  final double batimento;
  final double respiracao;
  final double distancia;
  final int timestamp;

  const Leitura({
    required this.batimento,
    required this.respiracao,
    required this.distancia,
    required this.timestamp,
  });

  /// Converte um Map vindo do Firebase num objeto Leitura.
  /// O timestamp do Firebase (.sv timestamp) chega como número (millis).
  /// Valores nulos ou inválidos são tratados com defaults seguros.
  factory Leitura.fromMap(Map<dynamic, dynamic> map) {
    return Leitura(
      batimento: _parseDouble(map['batimento']),
      respiracao: _parseDouble(map['respiracao']),
      distancia: _parseDouble(map['distancia']),
      timestamp: _parseInt(map['timestamp']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
