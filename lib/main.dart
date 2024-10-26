// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for defaultTargetPlatform
import 'package:air_mouse/platforms/desktop.dart';
import 'package:air_mouse/platforms/mobile.dart'; // Assuming you have a mobile.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remote control app',
      theme: ThemeData(
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade300),
        useMaterial3: true,
      ),
      home: _getHomeWidget(),
    );
  }

  Widget _getHomeWidget() {
    // Check if the app is running on the web, desktop, or mobile
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return const DesktopApp(); // Desktop version
    } else {
      return const MobileApp(); // Mobile version
    }
  }
}
