import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SMSService {
  static const String _baseUrl = 'https://your-backend-url.com/api'; // Replace with your backend URL
  
  /// Send SMS notification when complaint is fixed
  static Future<bool> sendFixedNotification(String complaintId) async {
    try {
      // Get complaint details
      final complaintDoc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .get();

      if (!complaintDoc.exists) {
        print('Complaint not found');
        return false;
      }

      final complaintData = complaintDoc.data() as Map<String, dynamic>;
      final userId = complaintData['userId'];

      // Get user phone number
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('User not found');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final phoneNumber = userData['phone'];
      final userName = userData['username'];

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print('Phone number not found for user');
        return false;
      }

      // Send SMS via backend
      final response = await http.post(
        Uri.parse('$_baseUrl/send-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'message': 'Hi $userName, your complaint has been fixed! Thank you for reporting. - Fix My Campus',
          'complaintId': complaintId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('SMS sent successfully to $phoneNumber');
        
        // Log SMS in Firestore
        await FirebaseFirestore.instance
            .collection('complaints')
            .doc(complaintId)
            .update({
              'smsSent': true,
              'smsSentAt': FieldValue.serverTimestamp(),
            });
        
        return true;
      } else {
        print('Failed to send SMS: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  /// Send SMS for status update
  static Future<bool> sendStatusUpdateNotification(
    String complaintId,
    String newStatus,
  ) async {
    try {
      final complaintDoc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .get();

      if (!complaintDoc.exists) return false;

      final complaintData = complaintDoc.data() as Map<String, dynamic>;
      final userId = complaintData['userId'];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final phoneNumber = userData['phone'];
      final userName = userData['username'];

      if (phoneNumber == null || phoneNumber.isEmpty) return false;

      String statusMessage = '';
      switch (newStatus) {
        case 'under_work':
          statusMessage = 'Your complaint is now under work. We are working on it!';
          break;
        case 'fixed':
          statusMessage = 'Your complaint has been fixed! Thank you for reporting.';
          break;
        default:
          statusMessage = 'Your complaint status has been updated.';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/send-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'message': 'Hi $userName, $statusMessage - Fix My Campus',
          'complaintId': complaintId,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending status update SMS: $e');
      return false;
    }
  }
}
