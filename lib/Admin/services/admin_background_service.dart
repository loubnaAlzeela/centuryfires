import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'admin_orders_channel';
  static const _notificationId = 999;

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Admin Orders',
      description: 'Notifications for new customer orders',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('new_order'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,              // ✅ يشتغل تلقائياً
        autoStartOnBoot: true,        // ✅ يشتغل بعد إعادة تشغيل الجهاز
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Century Fries',
        initialNotificationContent: 'جاري مراقبة الطلبات الجديدة...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onIosBackground,
        autoStart: true,              // ✅ iOS auto start
      ),
    );
  }

  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> start() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
  }

  static Future<void> stop() async {
    _service.invoke("stop");
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    const supabaseUrl = 'https://vznqsmzqvliarvfcpaaq.supabase.co';
    const supabaseAnonKey = 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I';

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final supabase = Supabase.instance.client;

    RealtimeChannel? ordersChannel;

    // ✅ يبدأ الاستماع فوراً بدون انتظار رسالة
    Future<void> startListening() async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Century Fries",
          content: "جاري مراقبة الطلبات الجديدة...",
        );
      }

      ordersChannel?.unsubscribe();

      ordersChannel = supabase.channel('admin_bg_orders').onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          final orderId = payload.newRecord['id']?.toString() ?? 'new';
          final shortId =
              orderId.length > 6 ? orderId.substring(0, 6) : orderId;

          final FlutterLocalNotificationsPlugin notificationsPlugin =
              FlutterLocalNotificationsPlugin();

          notificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'طلب جديد! 🥗',
            'تم استلام طلب جديد رقم #$shortId',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                'Admin Orders',
                channelDescription: 'Notifications for new customer orders',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('new_order'),
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
                sound: 'new_order.mp3',
              ),
            ),
          );
        },
      );

      ordersChannel!.subscribe();
    }

    // ✅ ابدأ فوراً
    await startListening();

    // ✅ إعادة الاتصال كل 5 دقائق للتأكد من بقاء الاتصال حي
    Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        await ordersChannel?.unsubscribe();
        await startListening();
      } catch (_) {}
    });

    // استقبال أمر الإيقاف
    service.on("stop").listen((event) async {
      await ordersChannel?.unsubscribe();
      ordersChannel = null;

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Century Fries",
          content: "تم الإيقاف",
        );
      }
      service.stopSelf();
    });
  }
}
