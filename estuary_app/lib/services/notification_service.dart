import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Local notification channel (Android)
    const androidChannel = AndroidNotificationChannel(
      'estuary_alerts',
      '수질 경보',
      description: '부영양화 위험 알림',
      importance: Importance.high,
    );
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Save FCM token to Supabase
    final token = await _fcm.getToken();
    if (token != null) await SupabaseService.upsertFcmToken(token);

    _fcm.onTokenRefresh.listen(SupabaseService.upsertFcmToken);

    // Foreground messages → local notification
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        msg.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'estuary_alerts',
            '수질 경보',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }
}
