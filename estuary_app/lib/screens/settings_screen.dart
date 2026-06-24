import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/risk_status.dart';
import '../providers/location_provider.dart';
import '../providers/station_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _alertThreshold = 'yellow'; // 'yellow' or 'red'

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refresh();
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _alertThreshold = prefs.getString('alert_threshold') ?? 'yellow';
    });
  }

  Future<void> _setNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
    setState(() => _notificationsEnabled = v);
  }

  Future<void> _setThreshold(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alert_threshold', v);
    setState(() => _alertThreshold = v);
  }

  void _showAddLocationDialog() {
    final labelCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('알림 지점 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration:
                  const InputDecoration(labelText: '이름 (예: 내 양식장)'),
            ),
            TextField(
              controller: latCtrl,
              decoration:
                  const InputDecoration(labelText: '위도 (예: 37.41)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: lngCtrl,
              decoration:
                  const InputDecoration(labelText: '경도 (예: 126.73)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (label.isEmpty || lat == null || lng == null) return;
              Navigator.pop(ctx);
              await context.read<LocationProvider>().add(label, lat, lng);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    final stProvider = context.watch<StationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // ── Notifications ───────────────────────────────────────────
          _SectionHeader(title: '알림'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('푸시 알림'),
            subtitle: const Text('위험 수준 도달 시 알림 전송'),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _notificationsEnabled
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.tune,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 16),
                      const Expanded(
                          child: Text('알림 기준',
                              style: TextStyle(fontSize: 15))),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'yellow',
                              label: Text('주의 이상'),
                              icon: Icon(Icons.warning_amber, size: 14)),
                          ButtonSegment(
                              value: 'red',
                              label: Text('위험만'),
                              icon: Icon(Icons.dangerous, size: 14)),
                        ],
                        selected: {_alertThreshold},
                        onSelectionChanged: (s) =>
                            _setThreshold(s.first),
                        style: ButtonStyle(
                          textStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),

          const Divider(height: 32),

          // ── Registered locations ─────────────────────────────────────
          _SectionHeader(
            title: '알림 지점',
            action: TextButton.icon(
              icon: const Icon(Icons.add_location_alt, size: 16),
              label: const Text('추가'),
              onPressed: _showAddLocationDialog,
            ),
          ),

          if (locProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (locProvider.locations.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.location_off,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    '등록된 알림 지점이 없습니다.\n"추가" 버튼을 눌러 지점을 등록하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...locProvider.locations.map((loc) {
              RiskLevel nearestLevel = RiskLevel.green;
              double minDist = double.infinity;
              for (final s in stProvider.stations) {
                final d = _dist(loc.lat, loc.lng, s.lat, s.lng);
                if (d < minDist) {
                  minDist = d;
                  nearestLevel = stProvider.riskFor(s.id);
                }
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      nearestLevel.color.withValues(alpha: 0.15),
                  child:
                      Icon(nearestLevel.icon, color: nearestLevel.color),
                ),
                title: Text(loc.label),
                subtitle: Text(
                  '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: nearestLevel.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(nearestLevel.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 20),
                      onPressed: () =>
                          context.read<LocationProvider>().remove(loc.id),
                    ),
                  ],
                ),
              );
            }),

          const Divider(height: 32),

          // ── Alert history ─────────────────────────────────────────────
          _SectionHeader(title: '알림 기록'),

          if (locProvider.alerts.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('전송된 알림이 없습니다.',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            )
          else
            ...locProvider.alerts.map((alert) {
              final level = alert.level;
              return ListTile(
                dense: true,
                leading: Icon(level.icon, color: level.color, size: 20),
                title: Text('[${level.label}] ${alert.stationId ?? "알 수 없음"}',
                    style: TextStyle(
                        color: level.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                trailing: Text(
                  DateFormat('MM/dd HH:mm')
                      .format(alert.sentAt.toLocal()),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            }),

          const Divider(height: 32),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(title: '정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('데이터 출처'),
            subtitle: const Text('환경부 수질측정망 · data.go.kr'),
            onTap: () => _showInfoDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('위험 판단 알고리즘'),
            subtitle: const Text('BIO 임계값 규칙 기반'),
            onTap: () => _showAlgorithmDialog(context),
          ),
          const ListTile(
            leading: Icon(Icons.tag),
            title: Text('버전'),
            subtitle: Text('v1.0.0 · June 2026'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    final d1 = lat1 - lat2;
    final d2 = lng1 - lng2;
    return d1 * d1 + d2 * d2;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const Spacer(),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

void _showInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('데이터 출처'),
      content: const Text(
        '• 환경부 수질측정망 실시간 수질정보\n'
        '  (국립환경과학원 · data.go.kr)\n\n'
        '• 측정 항목: 수온, pH, 총인(T-P), 용존산소(DO)\n'
        '• 갱신 주기: 매 1시간\n\n'
        '이 앱의 예보는 참고 정보이며 공식 기관 발표를 대체하지 않습니다.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'))
      ],
    ),
  );
}

void _showAlgorithmDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('위험 판단 알고리즘'),
      content: const Text(
        'BIO 임계값 기반 규칙:\n\n'
        '🔴 위험\n'
        '  수온 ≥ 25°C AND 총인 ≥ 0.05 mg/L\n\n'
        '🟡 주의\n'
        '  위 조건 중 1가지 충족\n'
        '  또는 DO ≤ 4 mg/L\n'
        '  또는 pH ≥ 9.0\n\n'
        '🟢 정상\n'
        '  해당 없음',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'))
      ],
    ),
  );
}
