import 'package:flutter/material.dart';

import '../models/alert_event.dart';

/// Secção de alertas no dashboard.
///
/// Mostra alertas ativos ou "Nenhum alerta ativo" quando vazio.
/// Estilo consistente com os outros cards do dashboard.
class AlertSection extends StatelessWidget {
  final List<AlertEvent> activeAlerts;
  final VoidCallback? onSettingsTap;

  const AlertSection({
    super.key,
    required this.activeAlerts,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────
          Row(
            children: [
              Icon(
                Icons.notifications_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (activeAlerts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${activeAlerts.length}',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (onSettingsTap != null)
                GestureDetector(
                  onTap: onSettingsTap,
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ),
            ],
          ),

          // ── Conteúdo ──────────────────────────
          if (activeAlerts.isEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '🟢',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Nenhum alerta ativo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...activeAlerts.map((alert) => _AlertTile(alert: alert)),
          ],
        ],
      ),
    );
  }
}

/// Tile individual de um alerta.
class _AlertTile extends StatelessWidget {
  final AlertEvent alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor()),
      ),
      child: Row(
        children: [
          // Ícone
          Text(
            alert.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 10),

          // Mensagem + detalhes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (alert.relatedValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatRelatedValue(),
                    style: TextStyle(
                      color: _accentColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Timestamp
          Text(
            _formatTime(alert.timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _bgColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFF3A1A1A);
      case AlertSeverity.warning:
        return const Color(0xFF3A2A1A);
      case AlertSeverity.info:
        return const Color(0xFF1A2A1A);
    }
  }

  Color _borderColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444).withValues(alpha: 0.3);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B).withValues(alpha: 0.3);
      case AlertSeverity.info:
        return const Color(0xFF22C55E).withValues(alpha: 0.3);
    }
  }

  Color _accentColor() {
    switch (alert.type) {
      case AlertType.heartRateOutOfRange:
        return const Color(0xFFEF4444);
      case AlertType.respiratoryRateOutOfRange:
        return const Color(0xFF3B82F6);
      case AlertType.sensorOffline:
        return const Color(0xFFEF4444);
      case AlertType.sensorRecovered:
        return const Color(0xFF22C55E);
    }
  }

  String _formatRelatedValue() {
    switch (alert.type) {
      case AlertType.heartRateOutOfRange:
        return '${alert.relatedValue?.toStringAsFixed(0)} BPM';
      case AlertType.respiratoryRateOutOfRange:
        return '${alert.relatedValue?.toStringAsFixed(0)} RPM';
      default:
        return '';
    }
  }

  String _formatTime(int ts) {
    if (ts <= 0) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hh:$min';
    } catch (_) {
      return '';
    }
  }
}
