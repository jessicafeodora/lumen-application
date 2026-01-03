import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumen_application/firebase_options.dart';

import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'pages/auth_gate.dart';
import 'state/lamp_controller.dart';
import 'theme/lumen_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep your RTDB instance (as in your original code)
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-home-lamp-d68de-default-rtdb.firebaseio.com',
  );

  // ✅ RTDB persistence not supported on web
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }

  runApp(const LumenApp());
}

class LumenApp extends StatefulWidget {
  const LumenApp({super.key});

  @override
  State<LumenApp> createState() => _LumenAppState();
}

class _LumenAppState extends State<LumenApp> {
  final LampController controller = LampController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final light = LumenTheme.light;
        final dark = LumenTheme.dark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lúmen',
          themeMode: controller.themeMode,
          theme: light.copyWith(
            textTheme: GoogleFonts.interTextTheme(light.textTheme),
          ),
          darkTheme: dark.copyWith(
            textTheme: GoogleFonts.interTextTheme(dark.textTheme),
          ),

          // ✅ Start with splash → auth gate
          home: SplashPage(
            controller: controller,
            nextBuilder: () => AuthGate(controller: controller),
          ),

          routes: {
            '/settings': (_) => SettingsPage(controller: controller),
          },
        );
      },
    );
  }
}
