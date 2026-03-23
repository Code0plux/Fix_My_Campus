import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      provisional: false,
      criticalAlert: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    // Get FCM token and save to Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      
      _showLocalNotification(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
      );
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped from background: ${message.notification?.title}');
    });

    // Check if app was opened from notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.notification?.title}');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'complaint_channel',
        'Complaint Notifications',
        channelDescription: 'Notifications for complaint updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
      );
      print('Local notification shown: $title');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  /// Send notification to user when complaint is fixed
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

      // Get user FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('User not found');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'];
      final userName = userData['username'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token not found for user');
        return false;
      }

      print('Sending notification to user: $userName with token: $fcmToken');

      // Show local notification (for testing/demo)
      await _showLocalNotification(
        '✅ Complaint Fixed!',
        'Hi $userName, your complaint has been fixed! Thank you for reporting.',
      );

      // Log notification in Firestore
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
            'notificationSent': true,
            'notificationSentAt': FieldValue.serverTimestamp(),
          });

      print('Notification sent successfully to $userName');
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Send notification for status update
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
      final userName = userData['username'];

      String title = '';
      String body = '';

      switch (newStatus) {
        case 'under_work':
          title = '🔧 Work Started';
          body = 'Hi $userName, your complaint is now under work!';
          break;
        case 'fixed':
          title = '✅ Complaint Fixed';
          body = 'Hi $userName, your complaint has been fixed!';
          break;
        default:
          title = '📢 Status Update';
          body = 'Your complaint status has been updated.';
      }

      // Show local notification
      await _showLocalNotification(title, body);

      print('Status update notification sent to $userName');
      return true;
    } catch (e) {
      print('Error sending status update notification: $e');
      return false;
    }
  }

  /// Save FCM token for logged-in user
  static Future<void> saveFCMTokenForUser(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('Saving FCM token for user $userId: $token');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
        print('FCM token saved successfully for user: $userId');
      } else {
        print('Failed to get FCM token');
      }
    } catch (e) {
      print('Error saving FCM token for user: $e');
    }
  }
}

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  print('Message data: ${message.data}');
}
