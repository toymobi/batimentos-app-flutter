import 'package:flutter/material.dart';

/// Cores temáticas por tipo de sinal vital.
class VitalColors {
  final Color primary;
  final Color background;
  final Color iconBg;

  const VitalColors({
    required this.primary,
    required this.background,
    required this.iconBg,
  });
}

class VitalCard extends StatefulWidget {
  final String titulo;
  final String valor;
  final String unidade;
  final String? estado;
  final IconData icone;
  final VitalColors cores;
  final bool compact;

  const VitalCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.unidade,
    required this.icone,
    required this.cores,
    this.estado,
    this.compact = false,
  });

  @override
  State<VitalCard> createState() => _VitalCardState();
}

class _VitalCardState extends State<VitalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double? _previousValor;

  bool get _isHeart => widget.icone == Icons.favorite_rounded;

  @override
  void initState() {
    super.initState();
    _previousValor = double.tryParse(widget.valor);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant VitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valor != widget.valor) {
      final novoValor = double.tryParse(widget.valor);
      if (novoValor != null && _isHeart && _previousValor != null) {
        _triggerPulse();
      }
      _previousValor = novoValor;
    }
  }

  void _triggerPulse() {
    _pulseController.forward(from: 0.0);
    setState(() {
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(
          parent: _pulseController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;
    final novoValor = double.tryParse(widget.valor) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone + título
          Row(
            children: [
              ScaleTransition(
                scale: _isHeart
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.cores.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icone,
                    color: widget.cores.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.titulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 24 : 16),

          // Valor animado
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _previousValor ?? novoValor,
                  end: novoValor,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) {
                  final display = widget.unidade == 'cm'
                      ? valor.toStringAsFixed(1)
                      : valor.toStringAsFixed(0);
                  return Text(
                    display,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 48 : 40,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.unidade,
                  style: TextStyle(
                    color: widget.cores.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Estado com fade animado
          if (widget.estado != null) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(widget.estado),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.cores.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.estado!,
                  style: TextStyle(
                    color: widget.cores.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
