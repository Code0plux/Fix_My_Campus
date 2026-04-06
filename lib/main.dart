import 'package:fix_my_campus/Screen/login.dart';
import 'package:fix_my_campus/Screen/register.dart';
import 'package:fix_my_campus/Screen/admin_dashboard.dart';
import 'package:fix_my_campus/Screen/complaint_register.dart';
import 'package:fix_my_campus/Screen/splash_screen.dart';
import 'package:fix_my_campus/Screen/debug_screen.dart';
import 'package:fix_my_campus/Screen/notifications_screen.dart';
import 'package:fix_my_campus/mapScreen.dart';
import 'package:fix_my_campus/supabase_config.dart';
import 'package:fix_my_campus/services/notification_service.dart';
import 'package:fix_my_campus/core/constants/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    await SupabaseConfig.initialize();
    print('Supabase initialized successfully');
    
    await NotificationService().initialize();
    print('Notification service initialized successfully');

  } catch (e) {
    print('Initialization error: $e');
  }
  
  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fix My Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/home': (context) =>  MapScreen(),
        '/complaint': (context) => const ComplaintRegister(),
        '/debug': (context) => const DebugScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      initialRoute: '/',
    );
  }
}
