import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Show splash for at least 2 seconds
    await Future.delayed(Duration(seconds: 2));
    
    try {
      // Check if user is logged in
      bool isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Get saved user session
        final userSession = await _authService.getSavedUserSession();
        
        if (userSession != null) {
          print('Auto-login: ${userSession['email']}, isAdmin: ${userSession['isAdmin']}');
          
          // Navigate based on user role
          if (userSession['isAdmin'] == true) {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }
      
      // No valid session, go to login
      Navigator.pushReplacementNamed(context, '/login');
      
    } catch (e) {
      print('Error checking auth state: $e');
      // On error, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF91C788),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.school,
                size: 60,
                color: Color(0xFF91C788),
              ),
            ),
            
            SizedBox(height: 30),
            
            // App Name
            Text(
              'Fix My Campus',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 10),
            
            Text(
              'Report & Track Campus Issues',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            SizedBox(height: 50),
            
            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}