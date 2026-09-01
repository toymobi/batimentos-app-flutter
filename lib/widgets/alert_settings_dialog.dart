import 'package:flutter/material.dart';

import '../models/alert_settings.dart';

/// Diálogo de configuração dos limites de alerta.
///
/// Permite ao utilizador ajustar os limites técnicos para
/// batimento cardíaco, taxa respiratória e leituras consecutivas.
class AlertSettingsDialog extends StatefulWidget {
  final AlertSettings settings;

  const AlertSettingsDialog({super.key, required this.settings});

  /// Mostra o diálogo e retorna as novas configurações ou null se cancelado.
  static Future<AlertSettings?> show(
    BuildContext context,
    AlertSettings currentSettings,
  ) {
    return showDialog<AlertSettings>(
      context: context,
      builder: (context) => AlertSettingsDialog(settings: currentSettings),
    );
  }

  @override
  State<AlertSettingsDialog> createState() => _AlertSettingsDialogState();
}

class _AlertSettingsDialogState extends State<AlertSettingsDialog> {
  late TextEditingController _hrMinCtrl;
  late TextEditingController _hrMaxCtrl;
  late TextEditingController _rrMinCtrl;
  late TextEditingController _rrMaxCtrl;
  late TextEditingController _consecutiveCtrl;

  @override
  void initState() {
    super.initState();
    _hrMinCtrl =
        TextEditingController(text: widget.settings.heartRateMin.toString());
    _hrMaxCtrl =
        TextEditingController(text: widget.settings.heartRateMax.toString());
    _rrMinCtrl =
        TextEditingController(text: widget.settings.respiratoryRateMin.toString());
    _rrMaxCtrl =
        TextEditingController(text: widget.settings.respiratoryRateMax.toString());
    _consecutiveCtrl = TextEditingController(
        text: widget.settings.consecutiveReadingsRequired.toString());
  }

  @override
  void dispose() {
    _hrMinCtrl.dispose();
    _hrMaxCtrl.dispose();
    _rrMinCtrl.dispose();
    _rrMaxCtrl.dispose();
    _consecutiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2A3C)),
      ),
      title: Row(
        children: [
          const Icon(Icons.settings_rounded, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Configurar Alertas',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Batimento Cardíaco ────────────────
            _SectionHeader(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFEF4444),
              title: 'Batimento Cardíaco',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Mínimo (BPM)',
                    controller: _hrMinCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Máximo (BPM)',
                    controller: _hrMaxCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Taxa Respiratória ─────────────────
            _SectionHeader(
              icon: Icons.air_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Taxa Respiratória',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Mínimo (RPM)',
                    controller: _rrMinCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Máximo (RPM)',
                    controller: _rrMaxCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Geral ────────────────────────────
            _SectionHeader(
              icon: Icons.tune_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Geral',
            ),
            const SizedBox(height: 8),
            _NumberField(
              label: 'Leituras consecutivas para alerta',
              controller: _consecutiveCtrl,
            ),

            const SizedBox(height: 16),
            Text(
              'Os valores são limites técnicos, não diagnósticos médicos.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _save() {
    final newSettings = AlertSettings(
      heartRateMin: double.tryParse(_hrMinCtrl.text) ?? 50,
      heartRateMax: double.tryParse(_hrMaxCtrl.text) ?? 110,
      respiratoryRateMin: double.tryParse(_rrMinCtrl.text) ?? 8,
      respiratoryRateMax: double.tryParse(_rrMaxCtrl.text) ?? 25,
      consecutiveReadingsRequired:
          int.tryParse(_consecutiveCtrl.text) ?? 3,
    );
    Navigator.of(context).pop(newSettings);
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
