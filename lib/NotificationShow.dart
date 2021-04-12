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
    bool isBackgroundNotification = false;
    String channelId = 'BatteryNotifier',
        channelName = 'Battery Notifier',
        channelDescription =
            'Battery alerter with notification as per specified trigger';
    if (notificationCounter == 0) {
      isBackgroundNotification = true;
      channelId = 'BatteryNotifier0';
      channelName = 'Battery Notifier Initial';
      channelDescription =
          'Battery alerter with notification as per specified trigger';
    }
    final String notificationTitle =
        (!isBackgroundNotification) ? 'Alert' : 'Monitoring..';
    final String notificationText = ((!isBackgroundNotification)
            ? 'Alert: ' +
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

    final BigTextStyleInformation bigtextStyleInformation =
        BigTextStyleInformation(
      notificationText,
      htmlFormatBigText: true,
      contentTitle: 'Last update by ' +
          DateFormat.yMMMMd("en_US")
              .add_jms()
              .format(bMod.currBatteryDateTime!),
      htmlFormatContentTitle: true,
      summaryText: notificationTitle,
      htmlFormatSummaryText: true,
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId, channelName, channelDescription,
        importance: isBackgroundNotification ? Importance.low : Importance.max,
        priority: isBackgroundNotification ? Priority.high : Priority.low,
        indeterminate: isBackgroundNotification,
        // showProgress: false,
        // playSound : isBackgroundNotification,
        channelShowBadge: isBackgroundNotification,
        enableVibration: isBackgroundNotification,
        onlyAlertOnce: !isBackgroundNotification,
        ongoing: isBackgroundNotification,
        autoCancel: true,
        styleInformation: bigtextStyleInformation);
    final iOSPlatformChannelSpecifics = IOSNotificationDetails(
        presentSound: isBackgroundNotification,
        subtitle: bigtextStyleInformation.bigText);
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        notificationCounter, null, null, platformChannelSpecifics,
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
