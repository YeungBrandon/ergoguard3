import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait for consistent pose analysis
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ErgoGuardApp());
}

class ErgoGuardApp extends StatelessWidget {
  const ErgoGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ErgoGuard HK AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5276), // HK-inspired deep blue
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A5276),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: const Color(0xFF161B22),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/monitor': (context) => const MonitorScreen(),
        '/report': (context) => const ReportScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
