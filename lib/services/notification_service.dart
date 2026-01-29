import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'file_save_channel',
      'File Save Notifications',
      channelDescription: 'Notifications for file save events',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    // const NotificationDetails platformChannelSpecifics =
    //     NotificationDetails(android: androidPlatformChannelSpecifics);
    // await flutterLocalNotificationsPlugin.show(
    //   id,
    //   title,
    //   body,
    //   platformChannelSpecifics,
    // );
  }
}
