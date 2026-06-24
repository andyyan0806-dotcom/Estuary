import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';
import '../models/risk_status.dart';
import '../providers/station_provider.dart' show kDemoMode;
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import 'risk_explanation_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;
  final String stationName;

  const StationDetailScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  Measurement? _latest;
  RiskStatus? _risk;
  List<Measurement> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _latest = mockMeasurement(widget.stationId);
          _risk = mockRiskMap[widget.stationId];
          _history = mockHistory(widget.stationId);
          _loading = false;
        });
      }
      return;
    }

    final results = await Future.wait([
      SupabaseService.getLatestMeasurement(widget.stationId),
      SupabaseService.getLatestRisk(widget.stationId),
      SupabaseService.getMeasurementHistory(widget.stationId),
    ]);
    if (mounted) {
      setState(() {
        _latest = results[0] as Measurement?;
        _risk = results[1] as RiskStatus?;
        _history = (results[2] as List<Measurement>).reversed.toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _risk?.level ?? RiskLevel.green;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stationName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RiskBadge(level: level, risk: _risk),
                  const SizedBox(height: 16),
                  _MeasurementCards(m: _latest),
                  const SizedBox(height: 20),
                  const Text(
                    '최근 48시간 수온 추이',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 180, child: _TempChart(history: _history)),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('위험 판단 근거 보기'),
                    onPressed: _risk == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RiskExplanationScreen(
                                  stationName: widget.stationName,
                                  measurement: _latest,
                                  risk: _risk!,
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 8),
                  if (_risk != null)
                    Text(
                      '업데이트: ${DateFormat('MM/dd HH:mm').format(_risk!.ts.toLocal())}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final RiskStatus? risk;
  const _RiskBadge({required this.level, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.color, width: 2),
      ),
      child: Row(
        children: [
          Icon(level.icon, color: level.color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 위험도: ${level.label}',
                  style: TextStyle(
                    color: level.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (risk?.reason.isNotEmpty == true)
                  Text(
                    risk!.reason,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCards extends StatelessWidget {
  final Measurement? m;
  const _MeasurementCards({required this.m});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _ValueCard(label: '수온', value: m?.waterTemp, unit: '°C', threshold: 25.0, above: true),
        _ValueCard(label: '총인 (T-P)', value: m?.totalP, unit: 'mg/L', threshold: 0.05, above: true),
        _ValueCard(label: '용존산소 (DO)', value: m?.dissolvedO2, unit: 'mg/L', threshold: 4.0, above: false),
        _ValueCard(label: 'pH', value: m?.ph, unit: '', threshold: 9.0, above: true),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final double threshold;
  final bool above; // true = danger when above threshold
  const _ValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.threshold,
    required this.above,
  });

  bool get _isAlert {
    if (value == null) return false;
    return above ? value! >= threshold : value! <= threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isAlert
            ? Colors.orange.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isAlert ? Colors.orange : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            value != null ? '${value!.toStringAsFixed(2)}$unit' : '--',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isAlert ? Colors.orange.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempChart extends StatelessWidget {
  final List<Measurement> history;
  const _TempChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('데이터 없음'));
    }

    final spots = history.asMap().entries
        .where((e) => e.value.waterTemp != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.waterTemp!))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 25,
              color: Colors.red.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (_) => '25°C',
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
