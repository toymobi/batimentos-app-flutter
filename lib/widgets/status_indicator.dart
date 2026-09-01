import 'package:flutter/material.dart';

import '../models/sensor_status.dart';

/// Indicador de estado que mostra a ligação Firebase e o estado do sensor.
///
/// Firebase: mostra se o app está ligado ao Firebase.
/// Sensor: mostra se o ESP32 está a enviar dados (ativo/sem dados/offline).
class StatusIndicator extends StatelessWidget {
  final bool firebaseConectado;
  final SensorStatus sensorStatus;
  final String idadeLeitura;

  const StatusIndicator({
    super.key,
    required this.firebaseConectado,
    required this.sensorStatus,
    required this.idadeLeitura,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Firebase
        _StatusRow(
          label: 'Firebase',
          dotColor: firebaseConectado
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
          labelColor: firebaseConectado
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
          text: firebaseConectado ? 'Conectado' : 'Desconectado',
        ),
        const SizedBox(height: 6),
        // Sensor
        _StatusRow(
          label: 'Sensor',
          dotColor: _corSensor(sensorStatus),
          labelColor: _corSensor(sensorStatus),
          text: _textoSensor(sensorStatus),
          subtexto: _subtextoSensor(sensorStatus, idadeLeitura),
        ),
      ],
    );
  }

  Color _corSensor(SensorStatus status) {
    switch (status) {
      case SensorStatus.active:
        return const Color(0xFF22C55E);
      case SensorStatus.stale:
        return const Color(0xFFFBBF24);
      case SensorStatus.offline:
        return const Color(0xFFEF4444);
      case SensorStatus.unknown:
        return Colors.white38;
    }
  }

  String _textoSensor(SensorStatus status) {
    switch (status) {
      case SensorStatus.active:
        return 'Ativo';
      case SensorStatus.stale:
        return 'Sem dados recentes';
      case SensorStatus.offline:
        return 'Offline';
      case SensorStatus.unknown:
        return 'Sem dados';
    }
  }

  String? _subtextoSensor(SensorStatus status, String idade) {
    if (status == SensorStatus.unknown) return null;
    return 'Última leitura: $idade';
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color dotColor;
  final Color labelColor;
  final String text;
  final String? subtexto;

  const _StatusRow({
    required this.label,
    required this.dotColor,
    required this.labelColor,
    required this.text,
    this.subtexto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Linha principal: label + dot + texto
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label  ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Subtexto (idade da leitura)
        if (subtexto != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Text(
              subtexto!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
