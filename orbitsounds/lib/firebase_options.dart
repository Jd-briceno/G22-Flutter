import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return ios;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdN0V31w9xTyNGZDD753WWWrkt_AvHjY',
    appId: '1:84892838356:ios:b251b1f41f25002b904e41',
    messagingSenderId: '84892838356',
    projectId: 'orbitsounds-ef026',
    storageBucket: 'orbitsounds-ef026.appspot.com',
    iosBundleId: 'com.melodymuse',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdN0V31w9xTyNGZDD753WWWrkt_AvHjY',
    appId: '1:84892838356:android:27f4d9f6410f3d3b904e41',
    messagingSenderId: '84892838356',
    projectId: 'orbitsounds-ef026',
    storageBucket: 'orbitsounds-ef026.appspot.com',
  );
}