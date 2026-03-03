// File generated manually for FlutterFire multi-platform support.
// To regenerate, run: flutterfire configure
//
// ignore_for_file: type=lint
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNaMO7bSGagQ3gzC4A1hoSlDyXZ2yJrOM',
    appId: '1:722838385103:android:ce7c646915b9a331f362ba',
    messagingSenderId: '722838385103',
    projectId: 'qms-system-9267a',
    storageBucket: 'qms-system-9267a.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnTb8HEx-YCPgEXhldVBSOOo0Smkc-4d0',
    appId: '1:722838385103:web:374eeabc11b60679f362ba',
    messagingSenderId: '722838385103',
    projectId: 'qms-system-9267a',
    storageBucket: 'qms-system-9267a.firebasestorage.app',
    authDomain: 'qms-system-9267a.firebaseapp.com',
    measurementId: 'G-TBD00168CW',
  );

  // TODO: Jika ada iOS native di masa depan, tambahkan config iOS di sini.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNaMO7bSGagQ3gzC4A1hoSlDyXZ2yJrOM',
    appId: '1:722838385103:ios:XXXXXXXXXXXXXXXX', // GANTI jika deploy iOS native
    messagingSenderId: '722838385103',
    projectId: 'qms-system-9267a',
    storageBucket: 'qms-system-9267a.firebasestorage.app',
    iosBundleId: 'com.qms.presensi',
  );
}
