// File generated for DepthTrade
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWJ1ObWlMZDK8rtJ_qoScTcE2dPSKAmjU',
    appId: '1:564743082244:web:90349b654c93b92f114051',
    messagingSenderId: '564743082244',
    projectId: 'depth-trade',
    authDomain: 'depth-trade.firebaseapp.com',
    storageBucket: 'depth-trade.firebasestorage.app',
    measurementId: 'G-J1GVXYBP45',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWJ1ObWlMZDK8rtJ_qoScTcE2dPSKAmjU',
    appId: '1:564743082244:web:90349b654c93b92f114051',
    messagingSenderId: '564743082244',
    projectId: 'depth-trade',
    storageBucket: 'depth-trade.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWJ1ObWlMZDK8rtJ_qoScTcE2dPSKAmjU',
    appId: '1:564743082244:web:90349b654c93b92f114051',
    messagingSenderId: '564743082244',
    projectId: 'depth-trade',
    storageBucket: 'depth-trade.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAWJ1ObWlMZDK8rtJ_qoScTcE2dPSKAmjU',
    appId: '1:564743082244:web:90349b654c93b92f114051',
    messagingSenderId: '564743082244',
    projectId: 'depth-trade',
    storageBucket: 'depth-trade.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAWJ1ObWlMZDK8rtJ_qoScTcE2dPSKAmjU',
    appId: '1:564743082244:web:90349b654c93b92f114051',
    messagingSenderId: '564743082244',
    projectId: 'depth-trade',
    authDomain: 'depth-trade.firebaseapp.com',
    storageBucket: 'depth-trade.firebasestorage.app',
    measurementId: 'G-J1GVXYBP45',
  );
}
