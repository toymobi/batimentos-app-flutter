/// Tipos de alerta que o sistema pode gerar.
enum AlertType {
  /// Sensor deixou de enviar dados.
  sensorOffline,

  /// Sensor voltou a ficar ativo após período offline.
  sensorRecovered,

  /// Batimento cardíaco fora do intervalo configurado.
  heartRateOutOfRange,

  /// Taxa respiratória fora do intervalo configurado.
  respiratoryRateOutOfRange,
}

/// Severidade do alerta.
enum AlertSeverity {
  /// Informação técnica (ex: sensor recuperado).
  info,

  /// Aviso (ex: valores fora do intervalo).
  warning,

  /// Estado crítico (ex: sensor offline há muito tempo).
  critical,
}

/// Evento de alerta gerado pelo sistema de monitorização.
///
/// Cada alerta representa uma mudança de estado detetada:
/// sensor offline, valor fora do intervalo, recuperação, etc.
///
/// NÃO é diagnóstico médico — é indicação técnica de que
/// um valor está fora do intervalo configurado.
class AlertEvent {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final int timestamp;
  final double? relatedValue;
  final bool isResolved;
  final int? resolvedTimestamp;

  const AlertEvent({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.relatedValue,
    this.isResolved = false,
    this.resolvedTimestamp,
  });

  /// Cria uma cópia com campos opcionalmente alterados.
  AlertEvent copyWith({
    bool? isResolved,
    int? resolvedTimestamp,
  }) {
    return AlertEvent(
      type: type,
      severity: severity,
      message: message,
      timestamp: timestamp,
      relatedValue: relatedValue,
      isResolved: isResolved ?? this.isResolved,
      resolvedTimestamp: resolvedTimestamp ?? this.resolvedTimestamp,
    );
  }

  /// Converte para Map — preparado para persistência futura no Firebase.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'timestamp': timestamp,
      'relatedValue': relatedValue,
      'isResolved': isResolved,
      'resolvedTimestamp': resolvedTimestamp,
    };
  }

  /// Cria AlertEvent a partir de um Map do Firebase.
  factory AlertEvent.fromMap(Map<dynamic, dynamic> map) {
    return AlertEvent(
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.sensorOffline,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] is int ? map['timestamp'] : 0,
      relatedValue: (map['relatedValue'] as num?)?.toDouble(),
      isResolved: map['isResolved'] == true,
      resolvedTimestamp: map['resolvedTimestamp'] is int
          ? map['resolvedTimestamp']
          : null,
    );
  }

  /// Ícone para exibição na UI.
  String get icon {
    switch (type) {
      case AlertType.sensorOffline:
        return '🔴';
      case AlertType.sensorRecovered:
        return '🟢';
      case AlertType.heartRateOutOfRange:
        return '❤️';
      case AlertType.respiratoryRateOutOfRange:
        return '🫁';
    }
  }
}
