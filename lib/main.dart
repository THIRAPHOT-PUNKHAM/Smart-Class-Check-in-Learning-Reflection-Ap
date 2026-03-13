import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/finish_class_screen.dart';
import 'theme/app_theme.dart';

/// Entry point.
/// Firebase initialised with platform-specific options from firebase_options.dart.
/// App works fully offline (SQLite) if Firebase is not yet configured.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Init failed: $e');
  }

  runApp(const SmartCheckInApp());
}


class SmartCheckInApp extends StatelessWidget {
  const SmartCheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Class Check-in',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      // ── Named routes ──────────────────────────────────────────────
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {

          // Home (no arguments needed)
          case '/':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );

          // Check-in → receives { studentId: String }
          case '/checkin':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => CheckinScreen(
                studentId: args['studentId'] as String? ?? 'STD001',
              ),
            );

          // Finish class → receives { studentId: String, checkinId: int }
          case '/finish':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => FinishClassScreen(
                studentId: args['studentId'] as String? ?? 'STD001',
                checkinId: args['checkinId'] as int? ?? 0,
              ),
            );

          // Fallback
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
