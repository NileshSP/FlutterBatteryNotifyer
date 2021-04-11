import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:battery/battery.dart';
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

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    batteryMod = BatteryModel().fromJson(params!);
    battery = Battery();
    batteryStateSubscription =
        battery.onBatteryStateChanged.listen((BatteryState state) async {
      battery.batteryLevel.then((level) {
        batteryMod.currBatteryState = state;
        batteryMod.currBatteryLevel = level; //await battery.batteryLevel;
        batteryMod.currBatteryDateTime = DateTime.now();
      });
    });

    // show notification to simulate as app is running in background
    notificationSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      // final int bLevel = await battery.batteryLevel;
      // batteryMod.currBatteryLevel = bLevel;
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
        NotificationShow.notificationCounter = 0;
        NotificationShow.showNotification(batteryMod);
      } else {
        if (batteryMod.notifyBatteryLevel == batteryMod.currBatteryLevel &&
            (batteryMod.notifyBatteryState == batteryMod.currBatteryState ||
                batteryMod.currBatteryState == BatteryState.full)) {
          if (NotificationShow.notificationCounter == 0)
            NotificationShow.notificationCounter++;
          NotificationShow.showNotification(batteryMod);
        }
        NotificationShow.flutterLocalNotificationsPlugin.cancel(0);
        notificationSubscription.cancel();
        onStop();
      }
      print(DateFormat.yMMMMd("en_US").add_jms().format(DateTime.now()));
    });

    AudioServiceBackground.setState(playing: true);
  }

  @override
  Future<void> onStop() async {
    await batteryStateSubscription.cancel();
    // batteryStateSubscription = null;
    await notificationSubscription.cancel();
    // notificationSubscription = null;
    // battery = null;
    // batteryMod = null;
    AudioServiceBackground.setState(playing: false);
    await super.onStop();
  }
}
