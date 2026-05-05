import 'package:flutter/material.dart';
import 'package:super_app/features/home/screens/home_screen.dart';
import 'package:super_app/features/miniapp/services/webview_pool_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations before runApp
  await WebViewPoolService().init(); // Initialize the WebView pool
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
