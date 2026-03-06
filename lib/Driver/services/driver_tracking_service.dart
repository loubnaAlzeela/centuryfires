import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverTrackingService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'driver_tracking';
  static const _notificationId = 888;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // ✅ إضافة iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings, // ← هذا كان ناقص
    );

    await _notifications.initialize(initSettings);

    // Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Driver Tracking',
      description: 'Tracking driver location in background',
      importance: Importance.low,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Delivery Tracking',
        initialNotificationContent: 'Tracking active',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> start({
    required String orderId,
    required String driverUserId,
  }) async {
    var permission = await Geolocator.checkPermission();

    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _service.startService();
    _service.invoke("start", {
      "orderId": orderId,
      "driverUserId": driverUserId,
    });
  }

  static Future<void> stop() async {
    _service.invoke("stop");
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    StreamSubscription<Position>? positionStream;
    final supabase = Supabase.instance.client;

    DateTime lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

    service.on("start").listen((event) async {
      final orderId = (event?["orderId"] ?? '').toString();
      final driverUserId = (event?["driverUserId"] ?? '').toString();

      if (orderId.isEmpty || driverUserId.isEmpty) {
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Tracking Delivery",
            content: "❌ Missing orderId/driverUserId",
          );
        }
        return;
      }

      await positionStream?.cancel();

      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen((position) async {
            String statusText;

            try {
              await supabase.from('driver_locations').upsert({
                'order_id': orderId,
                'driver_id': driverUserId,
                'lat': position.latitude,
                'lng': position.longitude,
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'order_id');

              statusText =
                  "✅ ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
            } catch (e) {
              statusText = "❌ DB ERROR | $e";
            }

            if (service is AndroidServiceInstance) {
              final now = DateTime.now();
              if (now.difference(lastNotify).inSeconds >= 5) {
                lastNotify = now;
                service.setForegroundNotificationInfo(
                  title: "Tracking Delivery",
                  content: statusText,
                );
              }
            }
          });
    });

    service.on("stop").listen((event) async {
      await positionStream?.cancel();
      positionStream = null;

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Tracking Delivery",
          content: "Stopped",
        );
      }
    });
  }
}
