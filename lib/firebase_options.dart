import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoNwWLqoqlwjHGv_gJUj3EJE8L75OFbdg',
    appId: '1:907260348419:web:6af1c33e49dc810152e636',
    messagingSenderId: '907260348419',
    projectId: 'fix-my-campus-99d03',
    authDomain: 'fix-my-campus-99d03.firebaseapp.com',
    storageBucket: 'fix-my-campus-99d03.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYxO7r6Z4T9K4ishwFj0RVeohRwmB_lSA',
    appId: '1:907260348419:android:38124c76245d79ac52e636',
    messagingSenderId: '907260348419',
    projectId: 'fix-my-campus-99d03',
    storageBucket: 'fix-my-campus-99d03.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3HIa3yIXiDfNDoKzEFpQIVlF5gkRMU4o',
    appId: '1:907260348419:ios:e600638d5973981b52e636',
    messagingSenderId: '907260348419',
    projectId: 'fix-my-campus-99d03',
    storageBucket: 'fix-my-campus-99d03.firebasestorage.app',
    iosBundleId: 'com.example.fixMyCampus',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA3HIa3yIXiDfNDoKzEFpQIVlF5gkRMU4o',
    appId: '1:907260348419:ios:e600638d5973981b52e636',
    messagingSenderId: '907260348419',
    projectId: 'fix-my-campus-99d03',
    storageBucket: 'fix-my-campus-99d03.firebasestorage.app',
    iosBundleId: 'com.example.fixMyCampus',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAoNwWLqoqlwjHGv_gJUj3EJE8L75OFbdg',
    appId: '1:907260348419:web:bd04372629bd1c1a52e636',
    messagingSenderId: '907260348419',
    projectId: 'fix-my-campus-99d03',
    authDomain: 'fix-my-campus-99d03.firebaseapp.com',
    storageBucket: 'fix-my-campus-99d03.firebasestorage.app',
  );
}
