import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const isProd = bool.fromEnvironment('prod');

    if (kIsWeb) {
      return isProd ? webProd : webDev;
    }

    throw UnsupportedError('현재 플랫폼은 지원되지 않습니다.');
  }

  static const FirebaseOptions webProd = FirebaseOptions(
    apiKey: 'AIzaSyALx85H--jsrSwAC7NpW5wMjYlhMro5O_0',
    appId: '1:515447922918:web:XXXXXXXXX',
    messagingSenderId: '515447922918',
    projectId: 'team-sketch-omma',
    storageBucket: 'team-sketch-omma.appspot.com', // 👈
  );

  static const FirebaseOptions webDev = FirebaseOptions(
    apiKey: 'AIzaSyDsALhPsd-mEvSkV69DT31o22uq0Ph0Vao',
    appId: '1:421717640379:web:YYYYYYYYY',
    messagingSenderId: '421717640379',
    projectId: 'team-sketch-omma-dev',
    storageBucket: 'team-sketch-omma-dev.appspot.com', // 👈 이 부분!
  );
}
