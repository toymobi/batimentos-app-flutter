import 'package:flutter/material.dart';

/// Ponto de dados para o gráfico de linha.
class ChartPoint {
  final double timestamp; // Normalizado para 0..1
  final double value;

  const ChartPoint({required this.timestamp, required this.value});
}

/// Gráfico de linha suave com gradiente e animação de desenho progressivo.
///
/// A linha revela-se da esquerda para a direita quando os dados chegam.
class VitalLineChart extends StatefulWidget {
  final List<ChartPoint> points;
  final Color lineColor;
  final Color gradientColor;
  final String unit;
  final double? yMin;
  final double? yMax;

  const VitalLineChart({
    super.key,
    required this.points,
    required this.lineColor,
    required this.gradientColor,
    this.unit = '',
    this.yMin,
    this.yMax,
  });

  @override
  State<VitalLineChart> createState() => _VitalLineChartState();
}

class _VitalLineChartState extends State<VitalLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.points.isNotEmpty) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant VitalLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points && widget.points.isNotEmpty) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            if (w <= 0 || h <= 0) return const SizedBox.shrink();

            return CustomPaint(
              size: Size(w, h),
              painter: _LineChartPainter(
                points: widget.points,
                lineColor: widget.lineColor,
                gradientColor: widget.gradientColor,
                unit: widget.unit,
                yMin: widget.yMin,
                yMax: widget.yMax,
                animationValue: _animation.value,
              ),
            );
          },
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color lineColor;
  final Color gradientColor;
  final String unit;
  final double? yMin;
  final double? yMax;
  final double animationValue;

  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.gradientColor,
    required this.unit,
    this.yMin,
    this.yMax,
    required this.animationValue,
  });

  // ── Dimensões de padding ────────────────────────────────
  static const _padLeft = 40.0;
  static const _padRight = 12.0;
  static const _padTop = 12.0;
  static const _padBottom = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Clip progressivo: revela o gráfico da esquerda para a direita
    final clipWidth = size.width * animationValue;
    canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, size.height));

    if (points.length < 2) {
      _drawSinglePoint(canvas, size);
      return;
    }

    // Área útil do gráfico
    final chartW = size.width - _padLeft - _padRight;
    final chartH = size.height - _padTop - _padBottom;
    if (chartW <= 0 || chartH <= 0) return;

    // ── Range Y ───────────────────────────────────────────
    final values = points.map((p) => p.value).toList();
    final dataMin = yMin ?? values.reduce((a, b) => a < b ? a : b);
    final dataMax = yMax ?? values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;
    final yLow = range > 0 ? dataMin - range * 0.1 : dataMin - 1;
    final yHigh = range > 0 ? dataMax + range * 0.1 : dataMax + 1;
    final yRange = yHigh - yLow;

    // ── Converter pontos para coordenadas ──────────────────
    final offsets = points.map((p) {
      final x = _padLeft + (p.timestamp).clamp(0.0, 1.0) * chartW;
      final yNorm = yRange > 0 ? (p.value - yLow) / yRange : 0.5;
      final y = _padTop + chartH - (yNorm * chartH);
      return Offset(x, y);
    }).toList();

    // ── Eixo Y (linhas de grade + labels) ─────────────────
    _drawYAxis(canvas, size, yLow, yHigh, chartW, chartH);

    // ── Linha suave ───────────────────────────────────────
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildSmoothPath(offsets);
    canvas.drawPath(path, linePaint);

    // ── Gradiente debaixo da linha ────────────────────────
    final fillPath = Path.from(path);
    fillPath.lineTo(offsets.last.dx, _padTop + chartH);
    fillPath.lineTo(offsets.first.dx, _padTop + chartH);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientColor.withValues(alpha: 0.25),
          gradientColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, _padTop, size.width, chartH));

    canvas.drawPath(fillPath, gradientPaint);

    // ── Ponto no último valor ─────────────────────────────
    final last = offsets.last;
    final dotOuterPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(last, 6, dotOuterPaint);
    canvas.drawCircle(last, 3.5, dotInnerPaint);

    // ── Label do último valor ─────────────────────────────
    final lastValue = points.last.value;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: '${lastValue.toStringAsFixed(1)}$unit',
        style: TextStyle(
          color: lineColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = last.dx + 8;
    final labelY = last.dy - labelPainter.height / 2;
    // Se o label sair à direita, coloca à esquerda do ponto
    if (labelX + labelPainter.width > size.width - 4) {
      labelPainter.paint(
          canvas, Offset(last.dx - labelPainter.width - 8, labelY));
    } else {
      labelPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  /// Desenha um único ponto (quando só há 1 leitura).
  void _drawSinglePoint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dotOuterPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), 6, dotOuterPaint);
    canvas.drawCircle(Offset(cx, cy), 3.5, dotInnerPaint);
  }

  /// Constrói um caminho suave com curvas Catmull-Rom → Bezier.
  Path _buildSmoothPath(List<Offset> pts) {
    final path = Path();
    path.moveTo(pts.first.dx, pts.first.dy);

    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i == 0 ? i : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < pts.length ? i + 2 : pts.length - 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  /// Desenha linhas de grade horizontais + labels Y.
  void _drawYAxis(
    Canvas canvas,
    Size size,
    double yLow,
    double yHigh,
    double chartW,
    double chartH,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const numLines = 4;
    for (var i = 0; i <= numLines; i++) {
      final ratio = i / numLines;
      final y = _padTop + chartH - (ratio * chartH);
      final value = yLow + ratio * (yHigh - yLow);

      canvas.drawLine(
        Offset(_padLeft, y),
        Offset(_padLeft + chartW, y),
        gridPaint,
      );

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(2, y - labelPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax ||
        oldDelegate.animationValue != animationValue;
  }
}
