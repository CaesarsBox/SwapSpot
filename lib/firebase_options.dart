// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyC2Palk7kLEiyElYkgnke0o9wuvyDgiz2A',
    appId: '1:566237138164:web:96eb5f337937e39396e2a1',
    messagingSenderId: '566237138164',
    projectId: 'swapspot-8f99d',
    authDomain: 'swapspot-8f99d.firebaseapp.com',
    storageBucket: 'swapspot-8f99d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA83ux9xR7Cji5vKE0zMmzsOJeQynivOAc',
    appId: '1:566237138164:android:403e33f1e030939b96e2a1',
    messagingSenderId: '566237138164',
    projectId: 'swapspot-8f99d',
    storageBucket: 'swapspot-8f99d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAZO-8hEzJmZB6SufAmNZ2bYHNQNW2o45E',
    appId: '1:566237138164:ios:12290be466bf862b96e2a1',
    messagingSenderId: '566237138164',
    projectId: 'swapspot-8f99d',
    storageBucket: 'swapspot-8f99d.firebasestorage.app',
    iosBundleId: 'com.example.swapspot',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAZO-8hEzJmZB6SufAmNZ2bYHNQNW2o45E',
    appId: '1:566237138164:ios:12290be466bf862b96e2a1',
    messagingSenderId: '566237138164',
    projectId: 'swapspot-8f99d',
    storageBucket: 'swapspot-8f99d.firebasestorage.app',
    iosBundleId: 'com.example.swapspot',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC2Palk7kLEiyElYkgnke0o9wuvyDgiz2A',
    appId: '1:566237138164:web:442e959896a9a5d596e2a1',
    messagingSenderId: '566237138164',
    projectId: 'swapspot-8f99d',
    authDomain: 'swapspot-8f99d.firebaseapp.com',
    storageBucket: 'swapspot-8f99d.firebasestorage.app',
  );

}