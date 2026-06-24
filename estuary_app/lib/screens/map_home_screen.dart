import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/measurement.dart';
import '../models/risk_status.dart';
import '../models/station.dart';
import '../providers/station_provider.dart';
import '../services/mock_data.dart';
import '../widgets/city_labels_layer.dart';
import '../widgets/korea_map_layer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().refresh();
    });
  }

  void _openSheet(Station station, RiskStatus? risk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StationSheet(station: station, risk: risk),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(36.4, 127.8),
              initialZoom: 7.3,
              minZoom: 6.5,
              maxZoom: 14,
              backgroundColor: const Color(0xFF0A1628),
              cameraConstraint: CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  const LatLng(32.5, 123.8),
                  const LatLng(39.5, 132.0),
                ),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              const KoreaMapLayer(),
              const CityLabelsLayer(),
              MarkerLayer(
                markers: provider.stations.map((s) {
                  final risk = provider.riskMap[s.id];
                  final level = risk?.level ?? RiskLevel.green;
                  return Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _openSheet(s, risk),
                      child: _Marker(level: level),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Top status card ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _StatusCard(provider: provider),
          ),

          // ── Refresh button ─────────────────────────────────────────
          Positioned(
            bottom: 20,
            right: 16,
            child: _RefreshButton(
              loading: provider.isLoading,
              onTap: provider.refresh,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  final StationProvider provider;
  const _StatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final red    = provider.riskMap.values.where((r) => r.level == RiskLevel.red).length;
    final yellow = provider.riskMap.values.where((r) => r.level == RiskLevel.yellow).length;
    final green  = provider.riskMap.values.where((r) => r.level == RiskLevel.green).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F35).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.water, color: Color(0xFF4A9ECA), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '전국 수질 예보',
                  style: TextStyle(
                    color: Color(0xFFCFE2F3),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _Chip(count: red,    level: RiskLevel.red),
              const SizedBox(width: 6),
              _Chip(count: yellow, level: RiskLevel.yellow),
              const SizedBox(width: 6),
              _Chip(count: green,  level: RiskLevel.green),
              if (provider.lastUpdated != null) ...[
                const SizedBox(width: 10),
                Text(
                  DateFormat('HH:mm').format(provider.lastUpdated!),
                  style: const TextStyle(
                      color: Color(0xFF4A6A8A), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final int count;
  final RiskLevel level;
  const _Chip({required this.count, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: count > 0 ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: level.color.withValues(alpha: count > 0 ? 0.5 : 0.2),
            width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: count > 0 ? level.color : level.color.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REFRESH BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _RefreshButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _RefreshButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F35).withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A9ECA)),
                  )
                : const Icon(Icons.refresh,
                    color: Color(0xFF4A9ECA), size: 20),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARKER
// ═══════════════════════════════════════════════════════════════════════════════

class _Marker extends StatefulWidget {
  final RiskLevel level;
  const _Marker({required this.level});

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.level == RiskLevel.red) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.level.color;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          if (widget.level != RiskLevel.green)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(
                    alpha: widget.level == RiskLevel.red
                        ? 0.15 * _pulse.value
                        : 0.12),
              ),
            ),
          Container(
            width: widget.level == RiskLevel.red ? 18 : 16,
            height: widget.level == RiskLevel.red ? 18 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 10, spreadRadius: 1),
                BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET — STATION DETAIL
// ═══════════════════════════════════════════════════════════════════════════════

class _StationSheet extends StatefulWidget {
  final Station station;
  final RiskStatus? risk;
  const _StationSheet({required this.station, required this.risk});

  @override
  State<_StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<_StationSheet> {
  late final Measurement _m;
  late final List<Measurement> _history;

  @override
  void initState() {
    super.initState();
    _m = mockMeasurement(widget.station.id);
    _history = mockHistory(widget.station.id);
  }

  static const _regionNames = {
    'han_estuary':    '한강 하구',
    'incheon_coast':  '인천 해안',
    'west_sea':       '서해',
    'geum_river':     '금강',
    'yeongsan_river': '영산강',
    'south_sea':      '남해',
    'nakdong_river':  '낙동강',
    'east_sea':       '동해',
    'jeju':           '제주',
  };

  @override
  Widget build(BuildContext context) {
    final level  = widget.risk?.level ?? RiskLevel.green;
    final region = _regionNames[widget.station.region] ?? widget.station.region;

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.32,
      maxChildSize: 0.88,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1E32),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: level.color.withValues(alpha: 0.15),
                  border: Border.all(
                      color: level.color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(level.icon, color: level.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.station.name,
                      style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(region,
                      style: const TextStyle(
                          color: Color(0xFF4A6A8A), fontSize: 12)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: level.color.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(level.label,
                    style: TextStyle(
                        color: level.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ]),

            if (widget.risk?.reason.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: level.color.withValues(alpha: 0.2)),
                ),
                child: Text(widget.risk!.reason,
                    style: TextStyle(
                        color: level.color.withValues(alpha: 0.9),
                        fontSize: 12)),
              ),
            ],

            const SizedBox(height: 18),

            // ── Measurement cards ────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                _ValCard(label: '수온',        value: _m.waterTemp,   unit: '°C',   threshold: 25.0, above: true),
                _ValCard(label: '총인 (T-P)', value: _m.totalP,      unit: 'mg/L', threshold: 0.05, above: true),
                _ValCard(label: '용존산소',    value: _m.dissolvedO2, unit: 'mg/L', threshold: 4.0,  above: false),
                _ValCard(label: 'pH',          value: _m.ph,          unit: '',     threshold: 9.0,  above: true),
              ],
            ),

            const SizedBox(height: 18),

            // ── Chart ────────────────────────────────────────────────
            const Text('수온 추이 (48h)',
                style: TextStyle(
                    color: Color(0xFF8AB0CC),
                    fontSize: 12, fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            SizedBox(height: 130, child: _TempChart(history: _history)),

            if (widget.risk != null) ...[
              const SizedBox(height: 12),
              Text(
                '업데이트  ${DateFormat('MM/dd HH:mm').format(widget.risk!.ts.toLocal())}',
                style: const TextStyle(
                    color: Color(0xFF3A5A7A), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ValCard extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final double threshold;
  final bool above;
  const _ValCard({
    required this.label, required this.value,
    required this.unit,  required this.threshold, required this.above,
  });

  bool get _alert =>
      value != null && (above ? value! >= threshold : value! <= threshold);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _alert
            ? const Color(0xFF2A1A0A)
            : const Color(0xFF0D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _alert
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF4A6A8A), fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value != null ? '${value!.toStringAsFixed(2)} $unit' : '--',
            style: TextStyle(
              color: _alert ? Colors.orange.shade300 : const Color(0xFFCFE2F3),
              fontSize: 17, fontWeight: FontWeight.w700,
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
    final spots = history.asMap().entries
        .where((e) => e.value.waterTemp != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.waterTemp!))
        .toList();

    if (spots.isEmpty) return const SizedBox();

    return LineChart(LineChartData(
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (v, _) => Text(
            '${v.toInt()}°',
            style: const TextStyle(color: Color(0xFF3A5A7A), fontSize: 10),
          ),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: 25,
          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ]),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF3B82F6),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3B82F6).withValues(alpha: 0.25),
                const Color(0xFF3B82F6).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}
