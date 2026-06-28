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
import '../widgets/korea_mask_layer.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF060E1E);
const _surface = Color(0xFF0D1A2D);
const _card    = Color(0xFF112033);

const _accent  = Color(0xFF38BDF8);
const _t1      = Color(0xFFE8F1FA);
const _t2      = Color(0xFF5E7A96);
const _t3      = Color(0xFF2D4A6E);

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
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<StationProvider>().refresh());
  }

  void _open(Station s, RiskStatus? r) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _Sheet(station: s, risk: r),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StationProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // ── Map ─────────────────────────────────────────────────────
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(36.4, 127.8),
            initialZoom: 7.3,
            minZoom: 6.4,
            maxZoom: 14,
            backgroundColor: _bg,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(32.5, 123.5),
                const LatLng(39.5, 132.5),
              ),
            ),
          ),
          children: [
            // Dark tile base — shows real rivers, coastlines, roads
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.estuary.app',
              maxZoom: 20,
            ),
            // Dim non-Korea area so Korea is the visual focus
            const KoreaMaskLayer(),
            const CityLabelsLayer(),
            MarkerLayer(
              markers: p.stations.map((s) {
                final r = p.riskMap[s.id];
                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: 52,
                  height: 52,
                  child: GestureDetector(
                    onTap: () => _open(s, r),
                    child: _Pin(level: r?.level ?? RiskLevel.green),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Top fade
        Positioned(
          top: 0, left: 0, right: 0,
          height: 140,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bg, _bg.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),

        // ── Header ──────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16, right: 16,
          child: _Header(p: p),
        ),

        // ── Legend pill ──────────────────────────────────────────────
        Positioned(
          bottom: 24, left: 16,
          child: _Legend(),
        ),

        // ── Refresh ──────────────────────────────────────────────────
        Positioned(
          bottom: 24, right: 16,
          child: _RefreshBtn(
            loading: p.isLoading, onTap: p.refresh),
        ),
      ]),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final StationProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    final red    = p.riskMap.values.where((r) => r.level == RiskLevel.red).length;
    final yellow = p.riskMap.values.where((r) => r.level == RiskLevel.yellow).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전국 수질 예보', style: TextStyle(
                    color: _t1, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('한강 · 인천 · 전국 주요 수계',
                    style: TextStyle(color: _t2, fontSize: 11)),
                ],
              ),
            ),
            if (red > 0)
              _StatusPill(label: '위험 $red', color: const Color(0xFFFF4757)),
            if (red > 0) const SizedBox(width: 6),
            if (yellow > 0)
              _StatusPill(label: '주의 $yellow', color: const Color(0xFFFFD32A)),
            if (p.lastUpdated != null) ...[
              const SizedBox(width: 8),
              Text(DateFormat('HH:mm').format(p.lastUpdated!),
                style: const TextStyle(color: _t3, fontSize: 11)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Text(label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _LegendDot(color: Color(0xFF2ED573), label: '정상'),
              SizedBox(width: 10),
              _LegendDot(color: Color(0xFFFFD32A), label: '주의'),
              SizedBox(width: 10),
              _LegendDot(color: Color(0xFFFF4757), label: '위험'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _t2, fontSize: 11)),
    ],
  );
}

// ─── Refresh button ───────────────────────────────────────────────────────────

class _RefreshBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _RefreshBtn({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _surface.withValues(alpha: 0.85),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
              : const Icon(Icons.refresh, color: _accent, size: 20),
        ),
      ),
    ),
  );
}

// ─── Station pin ──────────────────────────────────────────────────────────────

class _Pin extends StatefulWidget {
  final RiskLevel level;
  const _Pin({required this.level});
  @override
  State<_Pin> createState() => _PinState();
}

class _PinState extends State<_Pin> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    if (widget.level == RiskLevel.red) _c.repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Color get _c2 {
    switch (widget.level) {
      case RiskLevel.red:    return const Color(0xFFFF4757);
      case RiskLevel.yellow: return const Color(0xFFFFD32A);
      case RiskLevel.green:  return const Color(0xFF2ED573);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, child) => Stack(alignment: Alignment.center, children: [
      // outer glow
      if (widget.level != RiskLevel.green)
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _c2.withValues(
              alpha: widget.level == RiskLevel.red ? 0.14 * _a.value : 0.1),
          ),
        ),
      // core
      Container(
        width: widget.level == RiskLevel.red ? 14 : 12,
        height: widget.level == RiskLevel.red ? 14 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _c2,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85), width: 2),
          boxShadow: [
            BoxShadow(color: _c2.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1),
            BoxShadow(color: _c2.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
          ],
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _Sheet extends StatefulWidget {
  final Station station;
  final RiskStatus? risk;
  const _Sheet({required this.station, required this.risk});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late final Measurement _m;
  late final List<Measurement> _hist;

  static const _regions = {
    'han_estuary': '한강 하구',    'incheon_coast': '인천 해안',
    'west_sea':    '서해',         'geum_river':    '금강',
    'yeongsan_river': '영산강',    'south_sea':     '남해',
    'nakdong_river':  '낙동강',    'east_sea':      '동해',
    'jeju':           '제주',
  };

  @override
  void initState() {
    super.initState();
    _m    = mockMeasurement(widget.station.id);
    _hist = mockHistory(widget.station.id);
  }

  Color get _riskColor {
    switch (widget.risk?.level ?? RiskLevel.green) {
      case RiskLevel.red:    return const Color(0xFFFF4757);
      case RiskLevel.yellow: return const Color(0xFFFFD32A);
      case RiskLevel.green:  return const Color(0xFF2ED573);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level  = widget.risk?.level ?? RiskLevel.green;
    final rc     = _riskColor;
    final region = _regions[widget.station.region] ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.54,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // ── Handle ──────────────────────────────────────────────
            Center(child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2)),
            )),

            // ── Title row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.station.name,
                      style: const TextStyle(
                        color: _t1, fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: rc,
                          boxShadow: [BoxShadow(color: rc.withValues(alpha: 0.7), blurRadius: 5)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(region, style: const TextStyle(color: _t2, fontSize: 13)),
                    ]),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: rc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: rc.withValues(alpha: 0.4)),
                  ),
                  child: Text(level.label,
                    style: TextStyle(
                      color: rc, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),

            // Reason strip
            if (widget.risk?.reason.isNotEmpty == true)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rc.withValues(alpha: 0.18)),
                ),
                child: Text(widget.risk!.reason,
                  style: TextStyle(color: rc.withValues(alpha: 0.85), fontSize: 12)),
              ),

            // ── Metrics grid ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(children: [
                Expanded(child: Column(children: [
                  _MetricCard(
                    icon: Icons.thermostat, label: '수온',
                    value: _m.waterTemp, unit: '°C',
                    threshold: 25.0, above: true),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.bubble_chart, label: '용존산소',
                    value: _m.dissolvedO2, unit: 'mg/L',
                    threshold: 4.0, above: false),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(children: [
                  _MetricCard(
                    icon: Icons.science, label: '총인 (T-P)',
                    value: _m.totalP, unit: 'mg/L',
                    threshold: 0.05, above: true),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.opacity, label: 'pH',
                    value: _m.ph, unit: '',
                    threshold: 9.0, above: true),
                ])),
              ]),
            ),

            // ── Chart ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                const Text('수온 추이', style: TextStyle(
                  color: _t2, fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
                const Spacer(),
                const Text('48시간', style: TextStyle(
                  color: _t3, fontSize: 11)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: SizedBox(
                height: 120,
                child: _Chart(history: _hist),
              ),
            ),

            if (widget.risk != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                child: Text(
                  '업데이트  ${DateFormat('MM/dd HH:mm').format(widget.risk!.ts.toLocal())}',
                  style: const TextStyle(color: _t3, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Metric card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? value;
  final String unit;
  final double threshold;
  final bool above;

  const _MetricCard({
    required this.icon,    required this.label,
    required this.value,   required this.unit,
    required this.threshold, required this.above,
  });

  bool get _alert =>
      value != null && (above ? value! >= threshold : value! <= threshold);

  Color get _color => _alert ? const Color(0xFFFF6B35) : _accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _alert
              ? const Color(0xFFFF6B35).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              color: _color.withValues(alpha: 0.7),
              fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 8),
          Text(
            value != null ? value!.toStringAsFixed(2) : '--',
            style: TextStyle(
              color: _alert ? const Color(0xFFFF8C42) : _t1,
              fontSize: 22, fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          ),
          Text(unit.isEmpty ? '' : unit,
            style: const TextStyle(color: _t3, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Chart ────────────────────────────────────────────────────────────────────

class _Chart extends StatelessWidget {
  final List<Measurement> history;
  const _Chart({required this.history});

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
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) => Text('${v.toInt()}°',
            style: const TextStyle(color: _t3, fontSize: 9)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: 25,
          color: const Color(0xFFFF4757).withValues(alpha: 0.45),
          strokeWidth: 1, dashArray: [4, 5],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (_) => '25°C',
            style: const TextStyle(color: Color(0xFFFF4757), fontSize: 9),
            alignment: Alignment.topRight,
          ),
        ),
      ]),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _accent,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                _accent.withValues(alpha: 0.22),
                _accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}
