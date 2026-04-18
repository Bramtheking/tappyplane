// Firebase configuration for web
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCUqhNmUtX7Ok7l1--0piFiCwMtLUl59c4',
    authDomain: 'tappyplane-a3564.firebaseapp.com',
    projectId: 'tappyplane-a3564',
    storageBucket: 'tappyplane-a3564.firebasestorage.app',
    messagingSenderId: '402937476289',
    appId: '1:402937476289:web:4ac09504ba9c4f07ae1040',
    measurementId: 'G-86NB6K5RQK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUqhNmUtX7Ok7l1--0piFiCwMtLUl59c4',
    authDomain: 'tappyplane-a3564.firebaseapp.com',
    projectId: 'tappyplane-a3564',
    storageBucket: 'tappyplane-a3564.firebasestorage.app',
    messagingSenderId: '402937476289',
    appId: '1:402937476289:android:4ac09504ba9c4f07ae1040',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUqhNmUtX7Ok7l1--0piFiCwMtLUl59c4',
    authDomain: 'tappyplane-a3564.firebaseapp.com',
    projectId: 'tappyplane-a3564',
    storageBucket: 'tappyplane-a3564.firebasestorage.app',
    messagingSenderId: '402937476289',
    appId: '1:402937476289:ios:4ac09504ba9c4f07ae1040',
  );
}
