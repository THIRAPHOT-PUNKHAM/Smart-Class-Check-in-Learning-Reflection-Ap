// File: firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android; 
    }
  }

  // ── Android ──────────────────────────────────────────────────────
  // ดึงค่ามาจาก JSON ที่คุณแนบมาให้ครับ
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyhejf2URt4VFd53sU06KoBKxaN1k59PM',
    appId: '1:368480155407:android:97bf812736513cd1ac307a',
    messagingSenderId: '368480155407',
    projectId: 'smart-class-check-in-11848',
    storageBucket: 'smart-class-checkin-11848.firebasestorage.app',
  );

  // ── Web (ถ้ายังไม่มีข้อมูล ให้ใช้ Placeholder ไปก่อน หรือเพิ่มภายหลัง) ──
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '368480155407',
    projectId: 'smart-class-check-in-11848',
    authDomain: 'smart-class-check-in-11848.firebaseapp.com',
    storageBucket: 'smart-class-checkin-11848.firebasestorage.app',
  );

  // ── iOS (ถ้ามีแอป iOS ให้ทำตามขั้นตอนเดียวกับ Android เพื่อเอาค่ามาใส่) ──
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '368480155407',
    projectId: 'smart-class-check-in-11848',
    storageBucket: 'smart-class-checkin-11848.firebasestorage.app',
    iosBundleId: 'com.example.smart_class_checkin', 
  );
}