import 'package:flutter/material.dart';

import '../utils/data_aggregation.dart';

/// Secção de estatísticas calculada a partir de dados agregados.
///
/// Recebe pontos agregados e o número real de leituras,
/// calculando média, mínimo e máximo para cada métrica.
class StatisticsSection extends StatelessWidget {
  final List<AggregatedPoint> dadosGraficos;
  final int totalLeiturasReais;

  const StatisticsSection({
    super.key,
    required this.dadosGraficos,
    required this.totalLeiturasReais,
  });

  @override
  Widget build(BuildContext context) {
    if (dadosGraficos.isEmpty) return const SizedBox.shrink();

    // Calcular estatísticas a partir dos dados agregados
    final stats = _calcularStats(dadosGraficos);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──────────────────────────
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalLeiturasReais leitura${totalLeiturasReais == 1 ? '' : 's'} analisada${totalLeiturasReais == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWide ? 16 : 12),

            // ── Cards de estatísticas ──────────────
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      titulo: 'Batimento',
                      icone: Icons.favorite_rounded,
                      cor: const Color(0xFFEF4444),
                      unidade: 'BPM',
                      media: stats.averageBatimento,
                      minimo: stats.minBatimento,
                      maximo: stats.maxBatimento,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      titulo: 'Respiração',
                      icone: Icons.air_rounded,
                      cor: const Color(0xFF3B82F6),
                      unidade: 'RPM',
                      media: stats.averageRespiracao,
                      minimo: stats.minRespiracao,
                      maximo: stats.maxRespiracao,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      titulo: 'Distância',
                      icone: Icons.social_distance_rounded,
                      cor: const Color(0xFFF59E0B),
                      unidade: 'cm',
                      media: stats.averageDistancia,
                      minimo: stats.minDistancia,
                      maximo: stats.maxDistancia,
                    ),
                  ),
                ],
              )
            else ...[
              _StatCard(
                titulo: 'Batimento',
                icone: Icons.favorite_rounded,
                cor: const Color(0xFFEF4444),
                unidade: 'BPM',
                media: stats.averageBatimento,
                minimo: stats.minBatimento,
                maximo: stats.maxBatimento,
              ),
              const SizedBox(height: 12),
              _StatCard(
                titulo: 'Respiração',
                icone: Icons.air_rounded,
                cor: const Color(0xFF3B82F6),
                unidade: 'RPM',
                media: stats.averageRespiracao,
                minimo: stats.minRespiracao,
                maximo: stats.maxRespiracao,
              ),
              const SizedBox(height: 12),
              _StatCard(
                titulo: 'Distância',
                icone: Icons.social_distance_rounded,
                cor: const Color(0xFFF59E0B),
                unidade: 'cm',
                media: stats.averageDistancia,
                minimo: stats.minDistancia,
                maximo: stats.maxDistancia,
              ),
            ],

            // ── Range temporal ─────────────────────
            if (dadosGraficos.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TemporalRange(
                primeira: dadosGraficos.first.timestamp,
                ultima: dadosGraficos.last.timestamp,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Calcula estatísticas globais a partir dos pontos agregados.
  ///
  /// Usa os min/max de cada bucket para obter o min/max global,
  /// e calcula a média ponderada pelo número de leituras em cada bucket.
  _StatsData _calcularStats(List<AggregatedPoint> dados) {
    if (dados.isEmpty) return _StatsData.empty();

    // Mínimo e máximo globais (usando os min/max de cada bucket)
    var minBat = double.infinity;
    var maxBat = double.negativeInfinity;
    var minResp = double.infinity;
    var maxResp = double.negativeInfinity;
    var minDist = double.infinity;
    var maxDist = double.negativeInfinity;

    var sumBat = 0.0;
    var sumResp = 0.0;
    var sumDist = 0.0;
    var totalWeight = 0;
    var validDistCount = 0;

    for (final p in dados) {
      if (p.batimentoMin > 0 && p.batimentoMin < minBat) minBat = p.batimentoMin;
      if (p.batimentoMax > maxBat) maxBat = p.batimentoMax;
      if (p.respiracaoMin > 0 && p.respiracaoMin < minResp) {
        minResp = p.respiracaoMin;
      }
      if (p.respiracaoMax > maxResp) maxResp = p.respiracaoMax;
      if (p.distanciaAvg > 0) {
        if (p.distanciaAvg < minDist) minDist = p.distanciaAvg;
        if (p.distanciaAvg > maxDist) maxDist = p.distanciaAvg;
        sumDist += p.distanciaAvg;
        validDistCount++;
      }

      if (p.batimentoAvg > 0) {
        sumBat += p.batimentoAvg * p.count;
        totalWeight += p.count;
      }
      if (p.respiracaoAvg > 0) {
        sumResp += p.respiracaoAvg * p.count;
      }
    }

    return _StatsData(
      averageBatimento: totalWeight > 0 ? sumBat / totalWeight : 0,
      minBatimento: minBat == double.infinity ? 0 : minBat,
      maxBatimento: maxBat == double.negativeInfinity ? 0 : maxBat,
      averageRespiracao: totalWeight > 0 ? sumResp / totalWeight : 0,
      minRespiracao: minResp == double.infinity ? 0 : minResp,
      maxRespiracao: maxResp == double.negativeInfinity ? 0 : maxResp,
      averageDistancia:
          validDistCount > 0 ? sumDist / validDistCount : 0,
      minDistancia: minDist == double.infinity ? 0 : minDist,
      maxDistancia: maxDist == double.negativeInfinity ? 0 : maxDist,
    );
  }
}

/// Dados de estatísticas calculados.
class _StatsData {
  final double averageBatimento;
  final double minBatimento;
  final double maxBatimento;
  final double averageRespiracao;
  final double minRespiracao;
  final double maxRespiracao;
  final double averageDistancia;
  final double minDistancia;
  final double maxDistancia;

  const _StatsData({
    required this.averageBatimento,
    required this.minBatimento,
    required this.maxBatimento,
    required this.averageRespiracao,
    required this.minRespiracao,
    required this.maxRespiracao,
    required this.averageDistancia,
    required this.minDistancia,
    required this.maxDistancia,
  });

  factory _StatsData.empty() => const _StatsData(
        averageBatimento: 0,
        minBatimento: 0,
        maxBatimento: 0,
        averageRespiracao: 0,
        minRespiracao: 0,
        maxRespiracao: 0,
        averageDistancia: 0,
        minDistancia: 0,
        maxDistancia: 0,
      );
}

// ═══════════════════════════════════════════════════════════════
//  CARD DE ESTATÍSTICA
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  final String unidade;
  final double media;
  final double minimo;
  final double maximo;

  const _StatCard({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.unidade,
    required this.media,
    required this.minimo,
    required this.maximo,
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
          // Cabeçalho
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Média
          _StatRow(
            label: 'Média',
            value: _formatar(media),
            unidade: unidade,
            cor: cor,
            bold: true,
          ),
          const SizedBox(height: 10),

          // Mínimo
          _StatRow(
            label: 'Mínimo',
            value: _formatar(minimo),
            unidade: unidade,
            cor: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),

          // Máximo
          _StatRow(
            label: 'Máximo',
            value: _formatar(maximo),
            unidade: unidade,
            cor: Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  /// Formata o valor: inteiro se for exacto, 1 casa decimal caso contrário.
  String _formatar(double v) {
    if (v == 0) return '0.0';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

// ═══════════════════════════════════════════════════════════════
//  ROW DE ESTATÍSTICA
// ═══════════════════════════════════════════════════════════════

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String unidade;
  final Color cor;
  final bool bold;

  const _StatRow({
    required this.label,
    required this.value,
    required this.unidade,
    required this.cor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: cor,
                fontSize: 15,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unidade,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RANGE TEMPORAL
// ═══════════════════════════════════════════════════════════════

class _TemporalRange extends StatelessWidget {
  final int primeira;
  final int ultima;

  const _TemporalRange({required this.primeira, required this.ultima});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          color: Colors.white.withValues(alpha: 0.25),
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_formatar(primeira)}  →  ${_formatar(ultima)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatar(int ts) {
    if (ts <= 0) return '--';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm $hh:$min';
    } catch (_) {
      return '--';
    }
  }
}
