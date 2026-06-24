import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/location_provider.dart';
import 'providers/station_provider.dart';
import 'screens/map_home_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When kDemoMode == false, init Supabase + Firebase here:
  // await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  // await Firebase.initializeApp();
  // await NotificationService.init();

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
      title: '한강-인천 수질 예보',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1E32),
          foregroundColor: Color(0xFFCFE2F3),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F1E32),
          indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Color(0xFF8AB0CC), fontSize: 12),
          ),
        ),
        cardColor: const Color(0xFF0F1E32),
        dividerColor: Colors.white.withValues(alpha: 0.07),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFCFE2F3),
          iconColor: Color(0xFF4A9ECA),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF3B82F6)
                : const Color(0xFF4A6A8A),
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFCFE2F3)),
          bodySmall:  TextStyle(color: Color(0xFF8AB0CC)),
        ),
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _screens = [
    MapHomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '지도',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
