import 'dart:async';

import 'package:flutter/material.dart';

import '../models/alert_settings.dart';
import '../models/leitura.dart';
import '../models/sensor_status.dart';
import '../services/alert_service.dart';
import '../services/firebase_service.dart';
import '../utils/data_aggregation.dart';
import '../utils/time_period.dart';
import '../widgets/alert_section.dart';
import '../widgets/alert_settings_dialog.dart';
import '../widgets/statistics_section.dart';
import '../widgets/status_indicator.dart';
import '../widgets/time_filter.dart';
import '../widgets/vital_card.dart';
import '../widgets/vital_line_chart.dart';

// ── Paletas por sinal vital (top-level para acesso em qualquer classe do ficheiro)
const _batimentoCores = VitalColors(
  primary: Color(0xFFEF4444),
  background: Color(0xFF2A1A1A),
  iconBg: Color(0xFF3A1A1A),
);
const _respiracaoCores = VitalColors(
  primary: Color(0xFF3B82F6),
  background: Color(0xFF1A2A3A),
  iconBg: Color(0xFF1A2A3A),
);
const _distanciaCores = VitalColors(
  primary: Color(0xFFF59E0B),
  background: Color(0xFF2A2A1A),
  iconBg: Color(0xFF2A2A1A),
);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141420),
      body: StreamBuilder<Leitura?>(
        stream: _firebaseService.ultimaLeitura,
        builder: (context, snapshot) {
          return _buildBody(snapshot);
        },
      ),
    );
  }

  // ── Body principal ───────────────────────────────────────
  Widget _buildBody(AsyncSnapshot<Leitura?> snapshot) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _LoadingState();
    }

    // Erro
    if (snapshot.hasError) {
      return const _ErrorState();
    }

    // Sem dados
    final leitura = snapshot.data;
    if (leitura == null) {
      return const _NoDataState();
    }

    // Dados disponíveis
    return _DataState(
      leitura: leitura,
      historicoStream: _firebaseService.ultimasLeituras,
      firebaseService: _firebaseService,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ESTADOS
// ═══════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF3B82F6),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'A ligar ao sensor...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF3A1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar dados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verifique a ligação ao Firebase.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  const _NoDataState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A3C),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_off_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aguardando dados do sensor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nenhuma leitura disponível no momento.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DADOS DISPONÍVEIS
// ═══════════════════════════════════════════════════════════════

class _DataState extends StatefulWidget {
  final Leitura leitura;
  final Stream<List<Leitura>> historicoStream;
  final FirebaseService firebaseService;

  const _DataState({
    required this.leitura,
    required this.historicoStream,
    required this.firebaseService,
  });

  @override
  State<_DataState> createState() => _DataStateState();
}

class _DataStateState extends State<_DataState> {
  late Timer _timer;
  SensorStatus _sensorStatus = SensorStatus.unknown;
  String _idadeLeitura = '–';
  List<Leitura> _allLeituras = [];

  // ── Período ──────────────────────────────────────────────
  TimePeriod _periodoSelecionado = TimePeriod.fiveMinutes;
  bool _isLoadingPeriod = false;
  List<AggregatedPoint> _dadosGraficos = [];
  int _totalLeiturasReais = 0;

  // ── Alertas ──────────────────────────────────────────────
  final AlertService _alertService = AlertService();
  AlertSettings _alertSettings = AlertSettings();

  @override
  void initState() {
    super.initState();
    _sensorStatus = calcularSensorStatus(widget.leitura.timestamp);
    _idadeLeitura = formatarIdadeLeitura(widget.leitura.timestamp);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _atualizarEstado(widget.leitura.timestamp);
    });
  }

  @override
  void didUpdateWidget(covariant _DataState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leitura.timestamp != widget.leitura.timestamp) {
      _atualizarEstado(widget.leitura.timestamp);
    }
  }

  void _atualizarEstado(int timestamp) {
    final novoStatus = calcularSensorStatus(timestamp);
    final novaIdade = formatarIdadeLeitura(timestamp);

    // Atualizar sensor status
    if (novoStatus != _sensorStatus || novaIdade != _idadeLeitura) {
      setState(() {
        _sensorStatus = novoStatus;
        _idadeLeitura = novaIdade;
      });
    }

    // Verificar alertas do sensor
    final newAlerts = _alertService.check(
      lastReading: widget.leitura,
      currentSensorStatus: novoStatus,
      settings: _alertSettings,
    );
    if (newAlerts.isNotEmpty) {
      setState(() {});
    }
  }

  /// Chamado quando o utilizador muda o período.
  void _onPeriodoChanged(TimePeriod novoPeriodo) {
    setState(() {
      _periodoSelecionado = novoPeriodo;
      _isLoadingPeriod = true;
    });

    if (novoPeriodo == TimePeriod.fiveMinutes) {
      // Para 5 minutos, usar dados do stream (já temos)
      _processarDadosLocais();
    } else {
      // Para outros períodos, buscar do Firebase
      _buscarDadosPeriodo(novoPeriodo);
    }
  }

  /// Processa dados locais (stream) para o período de 5 minutos.
  void _processarDadosLocais() {
    final cutoff = DateTime.now()
        .subtract(_periodoSelecionado.duration)
        .millisecondsSinceEpoch;
    final filtradas =
        _allLeituras.where((l) => l.timestamp >= cutoff).toList();
    final aggregated = agregarLeituras(filtradas, _periodoSelecionado);
    setState(() {
      _dadosGraficos = aggregated;
      _totalLeiturasReais = filtradas.length;
      _isLoadingPeriod = false;
    });
  }

  /// Busca leituras do Firebase para um período específico.
  Future<void> _buscarDadosPeriodo(TimePeriod periodo) async {
    try {
      final leituras = await widget.firebaseService.leiturasPorPeriodo(periodo);
      final aggregated = agregarLeituras(leituras, periodo);

      // Verificar alertas com base nas leituras buscadas
      if (leituras.isNotEmpty) {
        final lastReading = leituras.last;
        final currentStatus = calcularSensorStatus(lastReading.timestamp);
        _alertService.check(
          lastReading: lastReading,
          currentSensorStatus: currentStatus,
          settings: _alertSettings,
        );
      }

      if (mounted) {
        setState(() {
          _dadosGraficos = aggregated;
          _totalLeiturasReais = leituras.length;
          _isLoadingPeriod = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPeriod = false;
        });
      }
    }
  }

  /// Abre o diálogo de configuração de alertas.
  Future<void> _openAlertSettings() async {
    final newSettings = await AlertSettingsDialog.show(
      context,
      _alertSettings,
    );
    if (newSettings != null) {
      setState(() {
        _alertSettings = newSettings;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Leitura>>(
      stream: widget.historicoStream,
      builder: (context, snapshot) {
        final streamData = snapshot.data ?? [];

        // Processar dados do stream para 5min de forma síncrona
        if (_periodoSelecionado == TimePeriod.fiveMinutes &&
            !_isLoadingPeriod) {
          _allLeituras = streamData;
          final cutoff = DateTime.now()
              .subtract(_periodoSelecionado.duration)
              .millisecondsSinceEpoch;
          final filtradas =
              _allLeituras.where((l) => l.timestamp >= cutoff).toList();
          final aggregated = agregarLeituras(filtradas, _periodoSelecionado);
          _dadosGraficos = aggregated;
          _totalLeiturasReais = filtradas.length;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: isWide ? 32 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── HEADER ─────────────────────────────
                      _Header(
                        firebaseConectado: true,
                        sensorStatus: _sensorStatus,
                        idadeLeitura: _idadeLeitura,
                        timestamp: widget.leitura.timestamp,
                      ),
                      SizedBox(height: isWide ? 36 : 28),

                      // ── CARDS PRINCIPAIS ───────────────────
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBatimentoCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRespiracaoCard()),
                          ],
                        )
                      else ...[
                        _buildBatimentoCard(),
                        const SizedBox(height: 12),
                        _buildRespiracaoCard(),
                      ],
                      SizedBox(height: isWide ? 16 : 12),

                      // ── CARD DISTÂNCIA ────────────────────
                      _buildDistanciaCard(),
                      SizedBox(height: isWide ? 36 : 28),

                      // ── FILTRO TEMPORAL ───────────────────
                      TimeFilter(
                        selecionado: _periodoSelecionado,
                        onChanged: _onPeriodoChanged,
                      ),
                      SizedBox(height: isWide ? 16 : 12),

                      // ── LOADING DO PERÍODO ────────────────
                      if (_isLoadingPeriod) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: isWide ? 16 : 12),
                      ],

                      // ── ALERTAS ──────────────────────────
                      if (!_isLoadingPeriod) ...[
                        AlertSection(
                          activeAlerts: _alertService.activeAlerts,
                          onSettingsTap: _openAlertSettings,
                        ),
                        SizedBox(height: isWide ? 36 : 28),
                      ],

                      // ── GRÁFICOS ──────────────────────────
                      if (!_isLoadingPeriod && _dadosGraficos.isNotEmpty) ...[
                        _GraficosSection(
                          dadosGraficos: _dadosGraficos,
                          totalLeituras: _totalLeiturasReais,
                        ),
                        SizedBox(height: isWide ? 36 : 28),
                      ],

                      // ── ESTATÍSTICAS ──────────────────────
                      if (!_isLoadingPeriod && _dadosGraficos.isNotEmpty) ...[
                        StatisticsSection(
                          dadosGraficos: _dadosGraficos,
                          totalLeiturasReais: _totalLeiturasReais,
                        ),
                        SizedBox(height: isWide ? 36 : 28),
                      ],

                      // ── FOOTER ─────────────────────────────
                      _Footer(timestamp: widget.leitura.timestamp),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBatimentoCard() {
    final bpm = widget.leitura.batimento.toStringAsFixed(0);
    return VitalCard(
      titulo: 'Batimento',
      valor: bpm,
      unidade: 'BPM',
      icone: Icons.favorite_rounded,
      cores: _batimentoCores,
      estado: _estadoBatimento(widget.leitura.batimento),
    );
  }

  Widget _buildRespiracaoCard() {
    final rpm = widget.leitura.respiracao.toStringAsFixed(0);
    return VitalCard(
      titulo: 'Respiração',
      valor: rpm,
      unidade: 'RPM',
      icone: Icons.air_rounded,
      cores: _respiracaoCores,
      estado: _estadoRespiracao(widget.leitura.respiracao),
    );
  }

  Widget _buildDistanciaCard() {
    final cm = widget.leitura.distancia.toStringAsFixed(1);
    final temLeitura = widget.leitura.distancia > 0;
    return VitalCard(
      titulo: 'Distância',
      valor: cm,
      unidade: 'cm',
      icone: Icons.social_distance_rounded,
      cores: _distanciaCores,
      estado: temLeitura ? 'Leitura válida' : 'Sem leitura',
      compact: true,
    );
  }

  // ── Classificações simples ────────────────────────────────
  String _estadoBatimento(double bpm) {
    if (bpm <= 0) return 'Sem dado';
    if (bpm >= 60 && bpm <= 100) return 'Normal';
    if (bpm < 60) return 'Baixo';
    return 'Elevado';
  }

  String _estadoRespiracao(double rpm) {
    if (rpm <= 0) return 'Sem dado';
    if (rpm >= 12 && rpm <= 20) return 'Normal';
    if (rpm < 12) return 'Baixa';
    return 'Elevada';
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool firebaseConectado;
  final SensorStatus sensorStatus;
  final String idadeLeitura;
  final int timestamp;

  const _Header({
    required this.firebaseConectado,
    required this.sensorStatus,
    required this.idadeLeitura,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Título
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitor de Sinais Vitais',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitorização em tempo real',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Indicadores de estado
            StatusIndicator(
              firebaseConectado: firebaseConectado,
              sensorStatus: sensorStatus,
              idadeLeitura: idadeLeitura,
            ),
          ],
        ),

        // Linha divisória
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GRÁFICOS
// ═══════════════════════════════════════════════════════════════

class _GraficosSection extends StatelessWidget {
  final List<AggregatedPoint> dadosGraficos;
  final int totalLeituras;

  const _GraficosSection({
    required this.dadosGraficos,
    required this.totalLeituras,
  });

  @override
  Widget build(BuildContext context) {
    if (dadosGraficos.isEmpty) return const SizedBox.shrink();

    // Converter para ChartPoints
    final batimentoPoints =
        _toChartPoints(dadosGraficos, (p) => p.batimentoAvg);
    final respiracaoPoints =
        _toChartPoints(dadosGraficos, (p) => p.respiracaoAvg);
    final distanciaPoints =
        _toChartPoints(dadosGraficos, (p) => p.distanciaAvg);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tendências',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalLeituras leitura${totalLeituras == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWide ? 16 : 12),

            // Gráficos
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _GraficoCard(
                      titulo: 'Batimento',
                      icone: Icons.favorite_rounded,
                      unidade: ' BPM',
                      cor: _batimentoCores.primary,
                      corGradiente: _batimentoCores.primary,
                      points: batimentoPoints,
                      atual: dadosGraficos.last.batimentoAvg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GraficoCard(
                      titulo: 'Respiração',
                      icone: Icons.air_rounded,
                      unidade: ' RPM',
                      cor: _respiracaoCores.primary,
                      corGradiente: _respiracaoCores.primary,
                      points: respiracaoPoints,
                      atual: dadosGraficos.last.respiracaoAvg,
                    ),
                  ),
                ],
              )
            else ...[
              _GraficoCard(
                titulo: 'Batimento',
                icone: Icons.favorite_rounded,
                unidade: ' BPM',
                cor: _batimentoCores.primary,
                corGradiente: _batimentoCores.primary,
                points: batimentoPoints,
                atual: dadosGraficos.last.batimentoAvg,
              ),
              const SizedBox(height: 12),
              _GraficoCard(
                titulo: 'Respiração',
                icone: Icons.air_rounded,
                unidade: ' RPM',
                cor: _respiracaoCores.primary,
                corGradiente: _respiracaoCores.primary,
                points: respiracaoPoints,
                atual: dadosGraficos.last.respiracaoAvg,
              ),
            ],
            SizedBox(height: isWide ? 12 : 12),

            // Distância (largura total)
            _GraficoCard(
              titulo: 'Distância',
              icone: Icons.social_distance_rounded,
              unidade: ' cm',
              cor: _distanciaCores.primary,
              corGradiente: _distanciaCores.primary,
              points: distanciaPoints,
              atual: dadosGraficos.last.distanciaAvg,
            ),
          ],
        );
      },
    );
  }

  /// Converte dados agregados para ChartPoint com timestamp normalizado (0..1).
  List<ChartPoint> _toChartPoints(
    List<AggregatedPoint> dados,
    double Function(AggregatedPoint) extractor,
  ) {
    if (dados.length < 2) {
      return dados.isEmpty
          ? []
          : [ChartPoint(timestamp: 0.5, value: extractor(dados.first))];
    }

    final firstTs = dados.first.timestamp;
    final lastTs = dados.last.timestamp;
    final range = lastTs - firstTs;

    return dados.map((p) {
      final t = range > 0 ? (p.timestamp - firstTs) / range : 0.5;
      return ChartPoint(timestamp: t, value: extractor(p));
    }).toList();
  }
}

class _GraficoCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String unidade;
  final Color cor;
  final Color corGradiente;
  final List<ChartPoint> points;
  final double atual;

  const _GraficoCard({
    required this.titulo,
    required this.icone,
    required this.unidade,
    required this.cor,
    required this.corGradiente,
    required this.points,
    required this.atual,
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
          // Cabeçalho do card
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
              const Spacer(),
              Text(
                '${atual.toStringAsFixed(1)}$unidade',
                style: TextStyle(
                  color: cor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfico
          SizedBox(
            height: 140,
            child: VitalLineChart(
              points: points,
              lineColor: cor,
              gradientColor: corGradiente,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOOTER
// ═══════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  final int timestamp;

  const _Footer({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              _formatarTimestamp(timestamp),
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

  String _formatarTimestamp(int ts) {
    if (ts <= 0) return 'Timestamp indisponível';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return 'Última leitura: $dd/$mm/$yyyy • $hh:$min:$ss';
    } catch (_) {
      return 'Timestamp indisponível';
    }
  }
}
