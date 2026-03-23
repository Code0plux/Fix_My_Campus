import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Token storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _isAdminKey = 'is_admin';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  // Save user session
  Future<void> _saveUserSession(User user, bool isAdmin, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await user.getIdToken();
    
    if (token != null) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, user.uid);
      await prefs.setBool(_isAdminKey, isAdmin);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_emailKey, user.email ?? '');
      
      print('User session saved: ${user.email}, isAdmin: $isAdmin');
    } else {
      print('Failed to get user token');
    }
  }
  
  // Get saved user session
  Future<Map<String, dynamic>?> getSavedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token == null) return null;
    
    return {
      'token': token,
      'userId': prefs.getString(_userIdKey),
      'isAdmin': prefs.getBool(_isAdminKey) ?? false,
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
    };
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final currentUser = _auth.currentUser;
    
    return token != null && currentUser != null;
  }
  
  // Clear user session
  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    
    print('User session cleared');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();
      
      bool isAdmin = userDoc['isAdmin'] ?? false;
      String username = userDoc['username'] ?? '';
      
      // Save user session
      await _saveUserSession(result.user!, isAdmin, username);
      
      return {
        'success': true,
        'isAdmin': isAdmin,
        'username': username,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'username': username,
        'email': email,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Save user session after registration
      await _saveUserSession(result.user!, false, username);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    await _clearUserSession();
    await _auth.signOut();
  }
}