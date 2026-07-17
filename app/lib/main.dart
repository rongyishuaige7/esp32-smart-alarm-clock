import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/alarm_provider.dart';
import 'pages/home_page.dart';
import 'pages/alarm_list_page.dart';
import 'pages/add_alarm_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmProvider(),
      child: MaterialApp(
        title: 'ESP32 Alarm Clock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D1B2A),
          cardTheme: CardThemeData(
            elevation: 0,
            color: const Color(0xFF1A2D42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D1B2A),
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF90CAF9)),
            titleTextStyle: TextStyle(
              color: Color(0xFFE3F2FD),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF42A5F5);
              }
              return const Color(0xFF546E7A);
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1565C0).withValues(alpha: 0.6);
              }
              return const Color(0xFF37474F);
            }),
          ),
          dividerColor: const Color(0xFF1E3A5F),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF1A2D42),
            contentTextStyle: TextStyle(color: Color(0xFFE3F2FD)),
          ),
        ),
        home: const HomePage(),
        routes: {
          '/alarms': (context) => const AlarmListPage(),
          '/add': (context) => const AddAlarmPage(),
        },
      ),
    );
  }
}
