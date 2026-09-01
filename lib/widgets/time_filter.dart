import 'package:flutter/material.dart';

import '../utils/time_period.dart';

/// Seletor horizontal de período temporal.
///
/// Mostra botões: 5 min | Dia | Semana | Mês
/// Estilo consistente com o dark theme do dashboard.
class TimeFilter extends StatelessWidget {
  final TimePeriod selecionado;
  final ValueChanged<TimePeriod> onChanged;

  const TimeFilter({
    super.key,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(
          'Intervalo:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        ...TimePeriod.values.map((periodo) {
          final isSelected = periodo == selecionado;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(periodo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  periodo.label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
