import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:battery/battery.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'BatteryModel.dart';
import 'NotificationShow.dart';

class BackgroundService extends BackgroundAudioTask {
  // ignore: cancel_subscriptions
  late StreamSubscription notificationSubscription;
  // ignore: cancel_subscriptions
  late StreamSubscription<BatteryState> batteryStateSubscription;
  late BatteryModel batteryMod;
  late Battery battery;
  int lastBatteryLevel = 0;

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    batteryMod = BatteryModel().fromJson(params!);
    battery = Battery();
    batteryStateSubscription =
        battery.onBatteryStateChanged.listen((BatteryState state) async {
      battery.batteryLevel.then((level) {
        batteryMod.currBatteryState = state;
        batteryMod.currBatteryLevel = level;
        batteryMod.currBatteryDateTime = DateTime.now();
      });
    });

    // show notification to simulate as app is running in background
    notificationSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      if ((batteryMod.currBatteryState == batteryMod.notifyBatteryState &&
                  (batteryMod.currBatteryState == BatteryState.charging &&
                      (batteryMod.currBatteryLevel <
                          batteryMod.notifyBatteryLevel)) ||
              (batteryMod.currBatteryState == BatteryState.discharging &&
                  (batteryMod.currBatteryLevel >
                      batteryMod.notifyBatteryLevel))) ||
          (batteryMod.currBatteryState == BatteryState.charging &&
              batteryMod.notifyBatteryState == BatteryState.full) ||
          (batteryMod.currBatteryState == BatteryState.full &&
              batteryMod.notifyBatteryState == BatteryState.discharging)) {
        if (lastBatteryLevel != batteryMod.currBatteryLevel) {
          NotificationShow.notificationCounter = 0;
          await NotificationShow.showNotification(batteryMod);
          lastBatteryLevel = batteryMod.currBatteryLevel;
          debugPrint(
              DateFormat.yMMMMd("en_US").add_jms().format(DateTime.now()) +
                  ' | battery state/level change notification delivered');
        }
      } else {
        if (batteryMod.notifyBatteryLevel == batteryMod.currBatteryLevel &&
            (batteryMod.notifyBatteryState == batteryMod.currBatteryState ||
                batteryMod.currBatteryState == BatteryState.full)) {
          await NotificationShow.flutterLocalNotificationsPlugin.cancelAll();
          if (NotificationShow.notificationCounter == 0)
            NotificationShow.notificationCounter++;
          await NotificationShow.showNotification(batteryMod);
          debugPrint(
              DateFormat.yMMMMd("en_US").add_jms().format(DateTime.now()) +
                  ' | final notification delivered');
        }
        this.onStop();
      }
      debugPrint(DateFormat.yMMMMd("en_US").add_jms().format(DateTime.now()));
    });

    AudioServiceBackground.setState(playing: true);
  }

  @override
  Future<void> onStop() async {
    await batteryStateSubscription.cancel();
    await notificationSubscription.cancel();
    AudioServiceBackground.setState(playing: false);
    await super.onStop();
  }
}
