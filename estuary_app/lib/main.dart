import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/location_provider.dart';
import 'providers/station_provider.dart';
import 'screens/map_home_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const EstuaryApp(),
    ),
  );
}

class EstuaryApp extends StatelessWidget {
  const EstuaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수질 예보',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _Shell(),
    );
  }

  ThemeData _buildTheme() {
    const bg      = Color(0xFF060E1E);
    const surface = Color(0xFF0D1A2D);
    const accent  = Color(0xFF38BDF8);
    const text1   = Color(0xFFE8F1FA);
    const text2   = Color(0xFF5E7A96);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary:   accent,
        secondary: Color(0xFF1D4ED8),
        surface:   surface,
        onPrimary: bg,
        onSurface: text1,
      ),
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        displaySmall: TextStyle(color: text1, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge:   TextStyle(color: text1, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium:  TextStyle(color: text1, fontWeight: FontWeight.w600, fontSize: 15),
        bodyMedium:   TextStyle(color: text1, fontSize: 14),
        bodySmall:    TextStyle(color: text2, fontSize: 12),
        labelSmall:   TextStyle(color: text2, fontSize: 11, letterSpacing: 0.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text1, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      dividerColor: Colors.white12,
      iconTheme: const IconThemeData(color: accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : const Color(0xFF2D4A6E)),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [MapHomeScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1525),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(icon: Icons.water_outlined,  activeIcon: Icons.water,   label: '지도',  index: 0, current: current, onTap: onTap),
              _NavItem(icon: Icons.tune_outlined,   activeIcon: Icons.tune,    label: '설정',  index: 1, current: current, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.icon, required this.activeIcon,
    required this.label, required this.index,
    required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    const accent = Color(0xFF38BDF8);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? activeIcon : icon,
                color: active ? accent : const Color(0xFF3A5A7A),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? accent : const Color(0xFF3A5A7A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
