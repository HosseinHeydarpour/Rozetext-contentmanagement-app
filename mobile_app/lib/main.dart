import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/connection_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local notifications
  try {
    await NotificationService.init();
  } catch (_) {}

  // Check saved server
  final savedServer = await StorageService.getServerUrl();

  runApp(InstagramContentManagerApp(
    hasInitialServer: savedServer != null && savedServer.isNotEmpty,
  ));
}

class InstagramContentManagerApp extends StatelessWidget {
  final bool hasInitialServer;

  const InstagramContentManagerApp({
    super.key,
    required this.hasInitialServer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت محتوای اینستاگرام',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE1306C),
          secondary: Color(0xFFF77737),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: hasInitialServer ? const HomeScreen() : const ConnectionScreen(),
      ),
    );
  }
}
