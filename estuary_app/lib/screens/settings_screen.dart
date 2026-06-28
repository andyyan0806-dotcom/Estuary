import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/location_provider.dart';

// ─── Palette (mirrors map screen) ─────────────────────────────────────────────
const _bg      = Color(0xFF060E1E);
const _surface = Color(0xFF0D1A2D);
const _card    = Color(0xFF0F1E32);
const _accent  = Color(0xFF38BDF8);
const _t1      = Color(0xFFE8F1FA);
const _t2      = Color(0xFF5E7A96);
const _t3      = Color(0xFF2D4A6E);

// ═══════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = false;
  int  _threshold    = 0; // 0 = 주의 이상, 1 = 위험만

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _notifEnabled = p.getBool('notif_enabled') ?? false;
      _threshold    = p.getInt('notif_threshold') ?? 0;
    });
  }

  Future<void> _setNotif(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif_enabled', v);
    setState(() => _notifEnabled = v);
  }

  Future<void> _setThreshold(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('notif_threshold', v);
    setState(() => _threshold = v);
  }

  void _addLocation(LocationProvider lp) {
    final nameCtrl = TextEditingController();
    final latCtrl  = TextEditingController();
    final lngCtrl  = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: '관심 지점 추가',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: nameCtrl, label: '이름 (라벨)', hint: '예) 내 양식장'),
            const SizedBox(height: 12),
            _DialogField(ctrl: latCtrl, label: '위도', hint: '37.41'),
            const SizedBox(height: 12),
            _DialogField(ctrl: lngCtrl, label: '경도', hint: '126.73'),
          ],
        ),
        onConfirm: () {
          final lat = double.tryParse(latCtrl.text);
          final lng = double.tryParse(lngCtrl.text);
          if (lat != null && lng != null && nameCtrl.text.isNotEmpty) {
            lp.add(nameCtrl.text, lat, lng);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocationProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _AppBarSliver(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Notifications ──────────────────────────────────
                _SectionHeader(icon: Icons.notifications_outlined, label: '알림'),
                const SizedBox(height: 8),
                _Card(children: [
                  _SwitchTile(
                    icon: Icons.notifications_active_outlined,
                    label: '푸시 알림',
                    subtitle: '수질 이상 시 즉시 알림',
                    value: _notifEnabled,
                    onChanged: _setNotif,
                  ),
                  _CardDivider(),
                  _SegmentTile(
                    icon: Icons.tune,
                    label: '알림 기준',
                    options: const ['주의 이상', '위험만'],
                    selected: _threshold,
                    onChanged: _notifEnabled ? _setThreshold : null,
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Watch locations ────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _SectionHeader(
                      icon: Icons.place_outlined, label: '관심 지점')),
                  GestureDetector(
                    onTap: () => _addLocation(lp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.35)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add, color: _accent, size: 14),
                        const SizedBox(width: 4),
                        const Text('추가', style: TextStyle(
                          color: _accent, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                if (lp.locations.isEmpty)
                  _EmptyCard(
                    icon: Icons.place_outlined,
                    message: '관심 지점을 추가하면\n해당 수역의 알림을 받을 수 있어요',
                  )
                else
                  _Card(children: [
                    for (int i = 0; i < lp.locations.length; i++) ...[
                      if (i > 0) _CardDivider(),
                      _LocationTile(
                        name: lp.locations[i].label,
                        lat:  lp.locations[i].lat,
                        lng:  lp.locations[i].lng,
                        onDelete: () => lp.remove(lp.locations[i].id),
                      ),
                    ],
                  ]),

                const SizedBox(height: 28),

                // ── Alert history ──────────────────────────────────
                _SectionHeader(icon: Icons.history, label: '알림 기록'),
                const SizedBox(height: 8),
                _AlertHistory(),

                const SizedBox(height: 28),

                // ── About ──────────────────────────────────────────
                _SectionHeader(icon: Icons.info_outline, label: '앱 정보'),
                const SizedBox(height: 8),
                _Card(children: [
                  _InfoTile(
                    icon: Icons.dataset_outlined,
                    label: '데이터 출처',
                    subtitle: '국가수자원관리종합정보시스템 (WAMIS)',
                    onTap: () => _showInfo(context, '데이터 출처',
                      '수온, pH, 용존산소 등의 측정값은\n'
                      '국가수자원관리종합정보시스템(WAMIS)에서\n'
                      '1시간 주기로 자동 수집됩니다.'),
                  ),
                  _CardDivider(),
                  _InfoTile(
                    icon: Icons.calculate_outlined,
                    label: '예측 알고리즘',
                    subtitle: 'BIO 지수 기반 부영양화 위험도 산정',
                    onTap: () => _showInfo(context, '예측 알고리즘',
                      '수온 ≥ 25°C, 총인 ≥ 0.05mg/L,\n'
                      '용존산소 ≤ 4mg/L, pH ≥ 9.0 등\n'
                      '복합 지표를 통해 녹조 위험도를 산정합니다.'),
                  ),
                  _CardDivider(),
                  _InfoTile(
                    icon: Icons.verified_outlined,
                    label: '버전',
                    subtitle: 'v1.0.0 · Demo Mode',
                    onTap: null,
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext ctx, String title, String body) =>
      showDialog(
        context: ctx,
        builder: (_) => _GlassDialog(
          title: title,
          content: Text(body,
            style: const TextStyle(
              color: _t2, fontSize: 13, height: 1.7)),
          onConfirm: null,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _AppBarSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정',
                style: TextStyle(
                  color: _t1, fontSize: 22, fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
              Text('알림 · 관심 지점 · 정보',
                style: TextStyle(color: _t3, fontSize: 12)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: _accent, size: 14),
    const SizedBox(width: 6),
    Text(label.toUpperCase(),
      style: const TextStyle(
        color: _accent, fontSize: 11, fontWeight: FontWeight.w700,
        letterSpacing: 1.2)),
  ]);
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white.withValues(alpha: 0.05),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon, required this.label, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _accent, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
            color: _t1, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: _t3, fontSize: 11)),
        ],
      )),
      Switch(value: value, onChanged: onChanged),
    ]),
  );
}

class _SegmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int>? onChanged;
  const _SegmentTile({
    required this.icon, required this.label,
    required this.options, required this.selected, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _t3.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _t2, size: 16),
      ),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(
        color: onChanged != null ? _t1 : _t3,
        fontSize: 14, fontWeight: FontWeight.w600)),
      const Spacer(),
      _SegmentControl(
        options: options, selected: selected,
        enabled: onChanged != null,
        onChanged: onChanged ?? (_) {},
      ),
    ]),
  );
}

class _SegmentControl extends StatelessWidget {
  final List<String> options;
  final int selected;
  final bool enabled;
  final ValueChanged<int> onChanged;
  const _SegmentControl({
    required this.options, required this.selected,
    required this.enabled, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: options.asMap().entries.map((e) {
        final active = e.key == selected && enabled;
        return GestureDetector(
          onTap: enabled ? () => onChanged(e.key) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? _accent.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: active
                  ? Border.all(color: _accent.withValues(alpha: 0.5))
                  : null,
            ),
            child: Text(e.value,
              style: TextStyle(
                color: active ? _accent : _t3,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ),
        );
      }).toList(),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback? onTap;
  const _InfoTile({
    required this.icon, required this.label,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _t3.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _t2, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                color: _t1, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(
                color: _t3, fontSize: 11)),
            ],
          )),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: _t3, size: 16),
        ]),
      ),
    ),
  );
}

class _LocationTile extends StatelessWidget {
  final String name;
  final double lat, lng;
  final VoidCallback onDelete;
  const _LocationTile({
    required this.name, required this.lat,
    required this.lng, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2ED573).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.place, color: Color(0xFF2ED573), size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(
            color: _t1, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            style: const TextStyle(color: _t3, fontSize: 11)),
        ],
      )),
      GestureDetector(
        onTap: onDelete,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4757).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.close,
            color: Color(0xFFFF4757), size: 14),
        ),
      ),
    ]),
  );
}

// ─── Alert history ────────────────────────────────────────────────────────────

const _demoAlerts = [
  _AlertItem('한강 하구 5번 지점', '위험 — 수온 27.1°C 초과',       '06/27 14:30', Color(0xFFFF4757)),
  _AlertItem('인천 연안 3번',     '주의 — 총인 0.06mg/L',          '06/26 09:15', Color(0xFFFFD32A)),
  _AlertItem('서해 2번 지점',     '위험 — 용존산소 3.8mg/L 이하',   '06/25 22:00', Color(0xFFFF4757)),
];

class _AlertItem {
  final String name, detail, time;
  final Color color;
  const _AlertItem(this.name, this.detail, this.time, this.color);
}

class _AlertHistory extends StatelessWidget {
  const _AlertHistory();

  @override
  Widget build(BuildContext context) {
    if (_demoAlerts.isEmpty) {
      return _EmptyCard(
        icon: Icons.notifications_off_outlined,
        message: '최근 알림 기록이 없습니다',
      );
    }

    return _Card(
      children: [
        for (int i = 0; i < _demoAlerts.length; i++) ...[
          if (i > 0) _CardDivider(),
          _AlertTile(item: _demoAlerts[i]),
        ],
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final _AlertItem item;
  const _AlertTile({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: item.color,
            boxShadow: [BoxShadow(
              color: item.color.withValues(alpha: 0.5), blurRadius: 6)],
          ),
        ),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(
            color: _t1, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(item.detail, style: TextStyle(
            color: item.color.withValues(alpha: 0.85), fontSize: 12)),
        ],
      )),
      Text(item.time, style: const TextStyle(color: _t3, fontSize: 10)),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _t3, size: 28),
        const SizedBox(height: 10),
        Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _t3, fontSize: 12, height: 1.6)),
      ],
    ),
  );
}

// ─── Glass dialog ─────────────────────────────────────────────────────────────

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onConfirm;
  const _GlassDialog({
    required this.title, required this.content, required this.onConfirm});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                color: _t1, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              content,
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _DialogBtn(
                  label: '취소', color: _t3,
                  onTap: () => Navigator.pop(context)),
                if (onConfirm != null) ...[
                  const SizedBox(width: 8),
                  _DialogBtn(
                    label: '확인', color: _accent,
                    onTap: () {
                      onConfirm!();
                      Navigator.pop(context);
                    }),
                ],
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DialogBtn({
    required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ),
  );
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  const _DialogField({
    required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
        color: _t2, fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 0.3)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: const TextStyle(color: _t1, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _t3, fontSize: 14),
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _accent.withValues(alpha: 0.6)),
          ),
        ),
      ),
    ],
  );
}
