import '../models/alert_event.dart';
import '../models/alert_settings.dart';
import '../models/leitura.dart';
import '../models/sensor_status.dart';

/// Serviço de deteção de alertas técnicos.
///
/// Analisa leituras e estado do sensor para gerar eventos de alerta.
/// NÃO gera diagnósticos médicos — apenas indica valores fora do
/// intervalo configurado ou estado do sensor.
///
/// Anti-falsos-alertas:
/// - Exige leituras consecutivas fora do intervalo
/// - Gera apenas um evento por mudança de estado
/// - Reseta contadores quando valores voltam ao normal
class AlertService {
  /// Histórico de alertas em memória.
  /// Preparado para persistência futura no Firebase.
  final List<AlertEvent> _alertHistory = [];

  /// Estado anterior do sensor (para detetar transições).
  SensorStatus _previousSensorStatus = SensorStatus.unknown;

  /// Contador de leituras consecutivas de batimento fora do intervalo.
  int _consecutiveHeartRateOut = 0;

  /// Contador de leituras consecutivas de respiração fora do intervalo.
  int _consecutiveRespiratoryOut = 0;

  /// Se já existe um alerta ativo de batimento fora do intervalo.
  bool _heartRateAlertActive = false;

  /// Se já existe um alerta ativo de respiração fora do intervalo.
  bool _respiratoryAlertActive = false;

  /// Histórico completo de alertas (ativos e resolvidos).
  List<AlertEvent> get history => List.unmodifiable(_alertHistory);

  /// Alertas atualmente ativos (não resolvidos).
  List<AlertEvent> get activeAlerts =>
      _alertHistory.where((a) => !a.isResolved).toList();

  /// Verifica leituras e estado do sensor, gerando alertas quando necessário.
  ///
  /// Deve ser chamado periodicamente (ex: a cada 5 segundos via Timer)
  /// e sempre que uma nova leitura chegar.
  ///
  /// Retorna novos alertas gerados nesta verificação.
  List<AlertEvent> check({
    required Leitura? lastReading,
    required SensorStatus currentSensorStatus,
    required AlertSettings settings,
  }) {
    final newAlerts = <AlertEvent>[];

    // ── Verificar estado do sensor ──────────────────────────
    final sensorAlerts = _checkSensorStatus(
      currentSensorStatus,
      lastReading?.timestamp ?? 0,
    );
    newAlerts.addAll(sensorAlerts);

    // ── Verificar batimento cardíaco ────────────────────────
    if (lastReading != null && lastReading.batimento > 0) {
      final hrAlerts = _checkHeartRate(lastReading.batimento, settings);
      newAlerts.addAll(hrAlerts);
    }

    // ── Verificar taxa respiratória ─────────────────────────
    if (lastReading != null && lastReading.respiracao > 0) {
      final rrAlerts = _checkRespiratoryRate(lastReading.respiracao, settings);
      newAlerts.addAll(rrAlerts);
    }

    // Atualizar estado anterior
    _previousSensorStatus = currentSensorStatus;

    return newAlerts;
  }

  /// Verifica transições de estado do sensor.
  List<AlertEvent> _checkSensorStatus(
    SensorStatus current,
    int timestamp,
  ) {
    final alerts = <AlertEvent>[];

    // Transição para offline
    if (current == SensorStatus.offline &&
        _previousSensorStatus != SensorStatus.offline) {
      // Verificar se já existe um alerta offline ativo
      final existingOffline = _alertHistory.any(
        (a) => a.type == AlertType.sensorOffline && !a.isResolved,
      );

      if (!existingOffline) {
        final age = _formatAge(timestamp);
        final alert = AlertEvent(
          type: AlertType.sensorOffline,
          severity: AlertSeverity.critical,
          message: 'Sensor offline — sem dados há $age',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        _alertHistory.add(alert);
        alerts.add(alert);
      }
    }

    // Transição de offline para ativo
    if (current == SensorStatus.active &&
        (_previousSensorStatus == SensorStatus.offline ||
            _previousSensorStatus == SensorStatus.stale)) {
      //Resolver alerta offline se existir
      final unresolvedOffline = _alertHistory
          .where(
            (a) => a.type == AlertType.sensorOffline && !a.isResolved,
          )
          .toList();

      for (final alert in unresolvedOffline) {
        final idx = _alertHistory.indexOf(alert);
        _alertHistory[idx] = alert.copyWith(
          isResolved: true,
          resolvedTimestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // Gerar alerta de recuperação
      final recovery = AlertEvent(
        type: AlertType.sensorRecovered,
        severity: AlertSeverity.info,
        message: 'Sensor voltou a ficar ativo',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _alertHistory.add(recovery);
      alerts.add(recovery);
    }

    return alerts;
  }

  /// Verifica batimento cardíaco fora do intervalo.
  List<AlertEvent> _checkHeartRate(double bpm, AlertSettings settings) {
    final alerts = <AlertEvent>[];
    final isOut = bpm < settings.heartRateMin || bpm > settings.heartRateMax;

    if (isOut) {
      _consecutiveHeartRateOut++;

      if (_consecutiveHeartRateOut >= settings.consecutiveReadingsRequired &&
          !_heartRateAlertActive) {
        _heartRateAlertActive = true;
        final alert = AlertEvent(
          type: AlertType.heartRateOutOfRange,
          severity: AlertSeverity.warning,
          message: 'Batimento fora do intervalo configurado',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          relatedValue: bpm,
        );
        _alertHistory.add(alert);
        alerts.add(alert);
      }
    } else {
      // Voltou ao intervalo — reseta contador e resolve alerta
      _consecutiveHeartRateOut = 0;

      if (_heartRateAlertActive) {
        _heartRateAlertActive = false;
        final unresolved = _alertHistory
            .where(
              (a) =>
                  a.type == AlertType.heartRateOutOfRange && !a.isResolved,
            )
            .toList();

        for (final alert in unresolved) {
          final idx = _alertHistory.indexOf(alert);
          _alertHistory[idx] = alert.copyWith(
            isResolved: true,
            resolvedTimestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
    }

    return alerts;
  }

  /// Verifica taxa respiratória fora do intervalo.
  List<AlertEvent> _checkRespiratoryRate(double rpm, AlertSettings settings) {
    final alerts = <AlertEvent>[];
    final isOut =
        rpm < settings.respiratoryRateMin || rpm > settings.respiratoryRateMax;

    if (isOut) {
      _consecutiveRespiratoryOut++;

      if (_consecutiveRespiratoryOut >= settings.consecutiveReadingsRequired &&
          !_respiratoryAlertActive) {
        _respiratoryAlertActive = true;
        final alert = AlertEvent(
          type: AlertType.respiratoryRateOutOfRange,
          severity: AlertSeverity.warning,
          message: 'Respiração fora do intervalo configurado',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          relatedValue: rpm,
        );
        _alertHistory.add(alert);
        alerts.add(alert);
      }
    } else {
      _consecutiveRespiratoryOut = 0;

      if (_respiratoryAlertActive) {
        _respiratoryAlertActive = false;
        final unresolved = _alertHistory
            .where(
              (a) =>
                  a.type == AlertType.respiratoryRateOutOfRange &&
                  !a.isResolved,
            )
            .toList();

        for (final alert in unresolved) {
          final idx = _alertHistory.indexOf(alert);
          _alertHistory[idx] = alert.copyWith(
            isResolved: true,
            resolvedTimestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
    }

    return alerts;
  }

  /// Formata a idade de uma leitura em formato legível.
  String _formatAge(int timestamp) {
    if (timestamp <= 0) return 'tempo desconhecido';
    final idade =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (idade.inSeconds < 60) return '${idade.inSeconds} segundos';
    if (idade.inMinutes < 60) return '${idade.inMinutes} minutos';
    if (idade.inHours == 1) return '1 hora';
    return '${idade.inHours} horas';
  }

  /// Reseta todo o estado do serviço.
  /// Útil para testes ou reinicialização.
  void reset() {
    _alertHistory.clear();
    _previousSensorStatus = SensorStatus.unknown;
    _consecutiveHeartRateOut = 0;
    _consecutiveRespiratoryOut = 0;
    _heartRateAlertActive = false;
    _respiratoryAlertActive = false;
  }
}
