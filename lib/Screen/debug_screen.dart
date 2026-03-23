import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String? _fcmToken;
  String? _savedToken;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await FirebaseMessaging.instance.getToken();
      
      setState(() {
        _userId = user?.uid;
        _fcmToken = token;
      });

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _savedToken = data['fcmToken'];
          });
        }
      }
    } catch (e) {
      print('Error loading debug info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: const Color(0xFF91C788),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Messaging Debug',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text('User ID: $_userId'),
                    const SizedBox(height: 8),
                    const Text('Current FCM Token:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(
                      _fcmToken ?? 'Loading...',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Text('Saved FCM Token in Firestore:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(
                      _savedToken ?? 'Not found',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _fcmToken == _savedToken
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _fcmToken == _savedToken
                            ? '✅ FCM Token is saved correctly'
                            : '❌ FCM Token mismatch! Token not saved properly',
                        style: TextStyle(
                          color: _fcmToken == _savedToken
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDebugInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF91C788),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
