import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/customization_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await CustomizationService.instance.load();
  runApp(const HeatSafetyApp());
}

class HeatSafetyApp extends StatelessWidget {
  const HeatSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '高溫工地健康監測',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
