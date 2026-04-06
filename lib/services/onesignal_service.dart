import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();

  factory OneSignalService() {
    return _instance;
  }

  OneSignalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save user's OneSignal ID when they log in
  Future<void> saveUserOneSignalId(String userEmail) async {
    try {
      final oneSignalId = await OneSignal.User.pushSubscription.id;

      if (oneSignalId == null || oneSignalId.isEmpty) {
        print('OneSignal ID not available');
        return;
      }

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'oneSignalId': oneSignalId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('OneSignal ID saved for user: $userEmail');
      }
    } catch (e) {
      print('Error saving OneSignal ID: $e');
    }
  }
}
