import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Archivo equivalente al generado por FlutterFire CLI.
///
/// Reemplaza estos valores con los de tu proyecto real si aun no ejecutaste:
/// `flutterfire configure`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web siempre usa configuracion explicita via FirebaseOptions.
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        // Requisito del proyecto:
        // para macOS usamos la misma configuracion que Web.
        // Esto permite conectar Firestore en macOS sin archivo nativo.
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Plataforma no configurada para Firebase.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAWqtQ_yzPXn67ksiXQ4jZc_TOWCfVeto',
    appId: '1:191881385523:web:de472c2073f41ee2897546',
    messagingSenderId: '191881385523',
    projectId: 'neurotrack-bad2f',
    authDomain: 'neurotrack-bad2f.firebaseapp.com',
    storageBucket: 'neurotrack-bad2f.firebasestorage.app',
    measurementId: 'G-3SXKVWRF9Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAsC9yzGnpqSBH7lrGF0DDVkC8uGvmzMs',
    appId: '1:191881385523:android:8234dc690345e24a897546',
    messagingSenderId: '191881385523',
    projectId: 'neurotrack-bad2f',
    storageBucket: 'neurotrack-bad2f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcq4FbBeWBFqpwaEz8toswf7UwBzp3F-k',
    appId: '1:191881385523:ios:e8aba840c66d53c3897546',
    messagingSenderId: '191881385523',
    projectId: 'neurotrack-bad2f',
    storageBucket: 'neurotrack-bad2f.firebasestorage.app',
    iosBundleId: 'com.example.neurotrack',
  );

  // macOS usa configuracion web por requerimiento.

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAcq4FbBeWBFqpwaEz8toswf7UwBzp3F-k',
    appId: '1:191881385523:ios:e8aba840c66d53c3897546',
    messagingSenderId: '191881385523',
    projectId: 'neurotrack-bad2f',
    storageBucket: 'neurotrack-bad2f.firebasestorage.app',
    iosBundleId: 'com.example.neurotrack',
  );

  // Debe apuntar al mismo proyecto Firebase.
}