import 'package:firebase_core/firebase_core.dart';
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
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCJSeyeLjPsaRwAcRDyvYj7wTHmoHhGR7Q',
    appId: '1:23405714280:web:7bafd67847b228e88d54dd',
    messagingSenderId: '23405714280',
    projectId: 'lexigo-1457f',
    authDomain: 'lexigo-1457f.firebaseapp.com',
    storageBucket: 'lexigo-1457f.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7BhdHTl0prbmYEac4sjGpOsKrJbeiQtY',
    appId: '1:23405714280:ios:a338371a87dccaae8d54dd',
    messagingSenderId: '23405714280',
    projectId: 'lexigo-1457f',
    storageBucket: 'lexigo-1457f.firebasestorage.app',
    iosBundleId: 'com.example.doAn',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7BhdHTl0prbmYEac4sjGpOsKrJbeiQtY',
    appId: '1:23405714280:ios:a338371a87dccaae8d54dd',
    messagingSenderId: '23405714280',
    projectId: 'lexigo-1457f',
    storageBucket: 'lexigo-1457f.firebasestorage.app',
    iosBundleId: 'com.example.doAn',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBenErVH0BgfMIkikP6vcV_gWb7KzVAevk',
    appId: '1:23405714280:android:eae7de664141870e8d54dd',
    messagingSenderId: '23405714280',
    projectId: 'lexigo-1457f',
    storageBucket: 'lexigo-1457f.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCJSeyeLjPsaRwAcRDyvYj7wTHmoHhGR7Q',
    appId: '1:23405714280:web:76a5a70857e6e9be8d54dd',
    messagingSenderId: '23405714280',
    projectId: 'lexigo-1457f',
    authDomain: 'lexigo-1457f.firebaseapp.com',
    storageBucket: 'lexigo-1457f.firebasestorage.app',
  );
}
