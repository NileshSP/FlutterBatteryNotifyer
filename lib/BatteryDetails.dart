import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:battery/battery.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'BatteryModel.dart';
import 'NotificationTriggers.dart';
import 'PageTransition.dart';

class BatteryDetails extends StatefulWidget {
  BatteryDetails({Key key, this.batteryMod}) : super(key: key);

  final BatteryModel batteryMod;

  @override
  BatteryDetailsState createState() => BatteryDetailsState();
}

class BatteryDetailsState extends State<BatteryDetails>
    with TickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamController<BatteryModel> batteryStreamController;
  Stream<BatteryModel> batteryStream;
  Battery battery = Battery();
  BatteryState newBatteryState, batteryStateNotifyVal;
  StreamSubscription<BatteryState> batteryStateSubscription;
  StreamSubscription dateTimeSubscription, notificationSubscription;
  BatteryModel batteryMod;
  AnimationController controllerShowIconOptions;

  static List<IconData> icons = [
    Icons.notifications,
    Icons.update,
    Icons.exit_to_app
  ];
  int fadeTime = 550;
  bool opacity = true;
  int notificationCounter = 0, newBatteryLevel = 0;
  var batteryColor = {'red': 0, 'green': 0};

  @override
  void initState() {
    super.initState();

    controllerShowIconOptions = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_batteryalert');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(
        initializationSettings); //, selectNotification: onSelectNotification);
    flutterLocalNotificationsPlugin.cancel(0);

    batteryMod = widget.batteryMod;

    batteryStreamController = StreamController<BatteryModel>.broadcast();
    batteryStream = batteryStreamController.stream.asyncMap((bMod) async {
      final int originalLevel = newBatteryLevel;
      final BatteryState _originalBatteryState = newBatteryState;
      newBatteryState = bMod.currBatteryState;
      newBatteryLevel = bMod.currBatteryLevel;
      setGreenToRed(newBatteryLevel);
      batteryMod.backgroundColor =
          Color.fromRGBO(batteryColor['red'], batteryColor['green'], 0, 1.0);
      batteryMod.frontTextColor = () {
        final colorVal = (batteryColor["red"] * 299 +
                batteryColor["green"] * 587 +
                0 * 114) ~/
            1000;
        return (colorVal >= 128) ? Colors.black : Colors.white;
      }();
      if (originalLevel != newBatteryLevel ||
          _originalBatteryState != newBatteryState) {
        if (originalLevel != 0 && _originalBatteryState != null) {
          if (newBatteryLevel == bMod.notifyBatteryLevel &&
              (bMod.notifyBatteryState == bMod.currBatteryState ||
                  bMod.currBatteryState == BatteryState.full)) {
            if (notificationCounter == 0) notificationCounter++;
            showNotification(bMod);
          }
          final printTxt = 'Widget rerendered to update as ' +
              bMod.getBatteryStateDisplayValue(bMod.currBatteryState) +
              ' with ' +
              bMod.currBatteryLevel.toString() +
              '% at ' +
              DateTime.now().toLocal().toString();
          //Scaffold.of(context).showSnackBar(SnackBar( content: Text(printTxt), action: null));
          debugPrint(printTxt);
          Stream.periodic(Duration(milliseconds: fadeTime), (s) => s)
              .take(4)
              .listen((_) => setState(() => opacity = !opacity));
        }
      }
      return bMod;
    });

    batteryStateSubscription =
        battery.onBatteryStateChanged.listen((BatteryState state) async {
      battery.batteryLevel.then((level) {
        batteryMod.currBatteryState = state;
        batteryMod.currBatteryLevel = level; //await battery.batteryLevel;
        batteryMod.currBatteryDateTime = DateTime.now();
        batteryStreamController.add(batteryMod);
      });
    });
    dateTimeSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      //batteryMod.currBatteryLevel = await battery.batteryLevel;
      batteryMod.currBatteryDateTime = DateTime.now();
      batteryStreamController.add(batteryMod);
    });

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('SystemChannels > $msg');
      if (msg == AppLifecycleState.resumed.toString()) {
        notificationSubscription?.cancel();
        await flutterLocalNotificationsPlugin.cancel(0);
        setState(() {});
      } else if (msg == AppLifecycleState.paused.toString()) {
        notificationSubscription =
            Stream.periodic(Duration(seconds: 1)).listen((_) async {
          final int bLevel = await battery.batteryLevel;
          batteryMod.currBatteryLevel = bLevel;
          if ((batteryMod.currBatteryState == batteryMod.notifyBatteryState &&
                      (batteryMod.currBatteryState == BatteryState.charging &&
                          (bLevel < batteryMod.notifyBatteryLevel)) ||
                  (batteryMod.currBatteryState == BatteryState.discharging &&
                      (bLevel > batteryMod.notifyBatteryLevel))) ||
              (batteryMod.currBatteryState == BatteryState.charging &&
                  batteryMod.notifyBatteryState == BatteryState.full) ||
              (batteryMod.currBatteryState == BatteryState.full &&
                  batteryMod.notifyBatteryState == BatteryState.discharging)) {
            notificationCounter = 0;
            showNotification(batteryMod);
          } else {
            flutterLocalNotificationsPlugin.cancel(0);
            notificationSubscription.cancel();
          }
        });
      }
      return '';
    });

    flutterLocalNotificationsPlugin.cancel(0);
  }

  Future onSelectNotification(String payload) async {
    try {
      if (payload != null) {
        Map mapObj = json.decode(payload);
        final String payloadCounter = mapObj['notificationCounter'].toString();
        debugPrint(
            'notification payload: notificationCounter is ' + payloadCounter);
      } else {
        debugPrint('notification payload not available!!');
      }
    } catch (e) {
      debugPrint('Error caused while reading notification payload : $e');
    }
  }

  Future showNotification(BatteryModel bMod) async {
    bool playSound = true;
    String channelId = 'BatteryNotifier',
        channelName = 'Battery Notifier',
        channelDescription =
            'Battery alerter with notification as per specified trigger';
    if (notificationCounter == 0) {
      playSound = false;
      channelId = 'BatteryNotifier0';
      channelName = 'Battery Notifier Initial';
      channelDescription =
          'Battery alerter with notification as per specified trigger';
    }
    final androidPlatformChannelSpecifics =
        AndroidNotificationDetails(channelId, channelName, channelDescription,
            importance: playSound ? Importance.max : Importance.low,
            priority: playSound ? Priority.low : Priority.high,
            // indeterminate: true,
            // showProgress: false,
            //playSound : playSound,
            channelShowBadge: playSound,
            enableVibration: playSound,
            onlyAlertOnce: !playSound,
            ongoing: !playSound,
            autoCancel: true,
            styleInformation: DefaultStyleInformation(true, true));
    final iOSPlatformChannelSpecifics =
        IOSNotificationDetails(presentSound: playSound);
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    final String notificationTitle = (playSound)
        ? 'Battery Alert'
        : 'Battery monitoring by ' +
            DateFormat.yMMMMd("en_US")
                .add_jms()
                .format(bMod.currBatteryDateTime);
    final String notificationText = ((playSound)
            ? 'Battery State: ' +
                bMod.getBatteryStateDisplayValue(bMod.currBatteryState) +
                ' with ' +
                bMod.currBatteryLevel.toString() +
                '% @ ' +
                DateFormat.yMMMMd("en_US")
                    .add_jms()
                    .format(bMod.currBatteryDateTime)
            : 'Notify @ ' +
                bMod.getBatteryStateDisplayValue(bMod.notifyBatteryState) +
                ' with ' +
                bMod.notifyBatteryLevel.toString() +
                '%, currently ' +
                bMod.currBatteryLevel.toString() +
                '% and ' +
                bMod.getBatteryStateDisplayValue(bMod.currBatteryState)
        //' - Background services are actively \n monitoring scheduled trigger'
        );
    await flutterLocalNotificationsPlugin.show(notificationCounter,
        notificationTitle, notificationText, platformChannelSpecifics,
        payload: JsonEncoder.withIndent(' ')
            .convert({'notificationCounter': notificationCounter}));
    //notificationCounter++;
  }

  setGreenToRed(int percent) {
    final int r = percent < 50 || percent == 0
        ? 255
        : (255 - (percent * 2 - 100) * 255 / 100).floor();
    final int g = percent > 50 || percent == 0
        ? 255
        : ((percent * 2) * 255 / 100).floor();
    batteryColor['red'] = r;
    batteryColor['green'] = int.tryParse(g.toString()) ?? g;
  }

  @override
  Widget build(BuildContext context) {
    final bool orientationState =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? true
            : false;
    final double txtScaleFactor = (3.2 *
        (orientationState
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height) /
        414.0);
    return Scaffold(
        key: Key('batDetails'),
        body: StreamBuilder(
            stream: batteryStream,
            builder:
                (BuildContext context, AsyncSnapshot<BatteryModel> snapshot) {
              if (snapshot.data == null ||
                  snapshot.data?.currBatteryState == null) {
                return Container();
              } else {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: OrientationBuilder(builder: (context, orientation) {
                    return Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.transparent,
                        ),
                        child: Column(
                            children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(30.0),
                          ),
                          orientationState
                              ? Hero(
                                  tag: 'heroAppTitle',
                                  child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 0,
                                          child: Text(batteryMod.appTitle,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 35.0,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ]),
                                )
                              : null,
                          orientationState
                              ? Padding(
                                  padding: EdgeInsets.all(20.0),
                                )
                              : null,
                          Expanded(
                            flex: 1,
                            child: Container(
                                width: MediaQuery.of(context).size.width - 100,
                                padding: EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: batteryMod.backgroundColor,
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0.0, 5.0),
                                      blurRadius: 5.0,
                                    )
                                  ],
                                ),
                                child: AnimatedOpacity(
                                  opacity: opacity ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: fadeTime),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          batteryMod
                                              .getBatteryStateDisplayValue(
                                                  snapshot
                                                      .data.currBatteryState),
                                          style: TextStyle(
                                            color: batteryMod.frontTextColor,
                                            fontSize: 11.0 * txtScaleFactor,
                                          ),
                                        ),
                                        Text(
                                          snapshot.data.currBatteryLevel
                                                  .toString() +
                                              '%',
                                          style: TextStyle(
                                            color: batteryMod.frontTextColor,
                                            fontSize: 30.0 * txtScaleFactor,
                                          ),
                                        ),
                                        Text(
                                          DateFormat.jms().format(snapshot
                                              .data.currBatteryDateTime),
                                          style: TextStyle(
                                            color: batteryMod.frontTextColor,
                                            fontSize: 8.0 * txtScaleFactor,
                                          ),
                                        ),
                                      ]),
                                )),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20.0),
                          ),
                        ].where((o) => o != null).toList()));
                  }),
                  floatingActionButton: floatingButton(snapshot),
                );
              }
            }));
  }

  Widget floatingButton(AsyncSnapshot<BatteryModel> snapshot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(icons.length, (int index) {
        Widget child = Container(
          height: 70.0,
          width: 56.0,
          alignment: FractionalOffset.topCenter,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: controllerShowIconOptions,
              curve: Interval(0.0, 1.0 - index / icons.length / 2.0,
                  curve: Curves.easeOut),
            ),
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: batteryMod.backgroundColor,
              mini: true,
              tooltip: (() {
                if (icons[index] == Icons.notifications) {
                  return 'view notification';
                } else if (icons[index] == Icons.update) {
                  return 'update notification trigger';
                } else if (icons[index] == Icons.exit_to_app) {
                  return 'close & exit';
                }
                return '';
              })(),
              child: Icon(icons[index], color: batteryMod.frontTextColor),
              onPressed: () {
                controllerShowIconOptions.reverse();
                if (icons[index] == Icons.notifications) {
                  notificationCounter =
                      notificationCounter == 0 ? 1 : notificationCounter;
                  showNotification(snapshot.data);
                } else if (icons[index] == Icons.update) {
                  Navigator.of(context).push(
                      //   MaterialPageRoute(builder: (context) =>
                      PageTransition(
                          widget: NotificationTriggers(snapshot.data),
                          tranType: 'fade',
                          tranDuration: 700)
                      //   )
                      );
                } else if (icons[index] == Icons.exit_to_app) {
                  //Navigator.pop(context);
                  SystemNavigator.pop();
                }
              },
            ),
          ),
        );
        return child;
      }).toList()
        ..add(
          FloatingActionButton(
            heroTag: 'navTriggers',
            backgroundColor: batteryMod.backgroundColor,
            child: AnimatedBuilder(
              animation: controllerShowIconOptions,
              builder: (BuildContext context, Widget child) {
                return Transform(
                  transform: Matrix4.rotationZ(
                      controllerShowIconOptions.value * 0.5 * math.pi),
                  alignment: FractionalOffset.center,
                  child: Icon(
                      controllerShowIconOptions.isDismissed
                          ? Icons.blur_on
                          : Icons.close,
                      color: batteryMod.frontTextColor,
                      size: 40.0),
                );
              },
            ),
            onPressed: () {
              if (controllerShowIconOptions.isDismissed) {
                controllerShowIconOptions.forward();
              } else {
                controllerShowIconOptions.reverse();
              }
            },
          ),
        ),
    );
  }

  @override
  void dispose() {
    (() async => await flutterLocalNotificationsPlugin.cancelAll())();
    batteryStateSubscription?.cancel();
    dateTimeSubscription?.cancel();
    notificationSubscription?.cancel();
    batteryStream = null;
    batteryStreamController?.close();
    batteryStreamController = null;
    controllerShowIconOptions?.dispose();
    controllerShowIconOptions = null;
    super.dispose();
  }
}
