import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'BatteryModel.dart';

class NotificationShow {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static int notificationCounter = 0;

  static Future showNotification(BatteryModel? bMod) async {
    bool notBackgroundNotification = true;
    String channelId = 'BatteryNotifier',
        channelName = 'Battery Notifier',
        channelDescription =
            'Battery alerter with notification as per specified trigger';
    if (notificationCounter == 0) {
      notBackgroundNotification = false;
      channelId = 'BatteryNotifier0';
      channelName = 'Battery Notifier Initial';
      channelDescription =
          'Battery alerter with notification as per specified trigger';
    }
    final String notificationTitle = (notBackgroundNotification)
        ? 'Battery Alert'
        : 'Last monitored on ' +
            DateFormat.yMMMMd("en_US")
                .add_jms()
                .format(bMod!.currBatteryDateTime!);
    final String notificationText = ((notBackgroundNotification)
            ? 'State: ' +
                bMod!.getBatteryStateDisplayValue(
                    batteryStateVal: bMod.currBatteryState) +
                ' with ' +
                bMod.currBatteryLevel.toString() +
                '% @ ' +
                DateFormat.yMMMMd("en_US")
                    .add_jms()
                    .format(bMod.currBatteryDateTime!)
            : 'Notify @ ' +
                bMod!.getBatteryStateDisplayValue(
                    batteryStateVal: bMod.notifyBatteryState) +
                ' with ' +
                bMod.notifyBatteryLevel.toString() +
                '%, currently ' +
                bMod.currBatteryLevel.toString() +
                '% and ' +
                bMod.getBatteryStateDisplayValue(
                    batteryStateVal: bMod.currBatteryState)
        //' - Background services are actively \n monitoring scheduled trigger'
        );
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId, channelName, channelDescription,
        importance: notBackgroundNotification ? Importance.max : Importance.low,
        priority: notBackgroundNotification ? Priority.low : Priority.high,
        indeterminate: notBackgroundNotification,
        // showProgress: false,
        // playSound : notBackgroundNotification,
        channelShowBadge: notBackgroundNotification,
        enableVibration: notBackgroundNotification,
        onlyAlertOnce: !notBackgroundNotification,
        ongoing: notBackgroundNotification,
        autoCancel: true);
    final iOSPlatformChannelSpecifics =
        IOSNotificationDetails(presentSound: notBackgroundNotification);
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(notificationCounter,
        notificationTitle, notificationText, platformChannelSpecifics,
        payload: JsonEncoder.withIndent(' ')
            .convert({'notificationCounter': notificationCounter}));
    //notificationCounter++;
  }

  // static Future onSelectNotification(String payload) async {
  //   try {
  //     if (payload != null) {
  //       Map mapObj = json.decode(payload);
  //       final String payloadCounter =
  //           mapObj['NotificationShow.notificationCounter'].toString();
  //       debugPrint(
  //           'notification payload: NotificationShow.notificationCounter is ' +
  //               payloadCounter);
  //     } else {
  //       debugPrint('notification payload not available!!');
  //     }
  //   } catch (e) {
  //     debugPrint('Error caused while reading notification payload : $e');
  //   }
  // }
}
