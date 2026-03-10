import 'package:fix_my_campus/Screen/login.dart';
import 'package:fix_my_campus/Screen/register.dart';
import 'package:fix_my_campus/Screen/admin_dashboard.dart';
import 'package:fix_my_campus/Screen/complaint_register.dart';
import 'package:fix_my_campus/mapScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/home': (context) =>  MapScreen(),
        '/complaint': (context) => const ComplaintRegister(),
      },
      initialRoute: '/login',
    );
  }
}
