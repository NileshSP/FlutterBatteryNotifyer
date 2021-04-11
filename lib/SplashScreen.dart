import 'package:flutter/material.dart';
import 'dart:async';
import 'BatteryModel.dart';
import 'BatteryDetails.dart';
import 'PageTransition.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  late BatteryModel bMod;
  late BatteryDetails batteryDetails;
  late StreamController<double> periodicController;
  late Stream<double> periodicStream;
  late StreamSubscription periodicSubscription;

  @override
  void initState() {
    super.initState();
    loadData();
    periodicController = StreamController<double>.broadcast();
    periodicStream = periodicController.stream.asyncMap((pVal) async {
      return pVal;
    });
    periodicSubscription = Stream.periodic(Duration(seconds: 1), (e) {
      return ((e + 1) * .20);
    }).listen((e) {
      periodicController.add(e);
    });
  }

  Future loadData() async {
    bMod = BatteryModel(appTitle: widget.title);
    await bMod.getPersistedValues();
    batteryDetails =
        BatteryDetails(key: new Key("defaultKey"), batteryMod: bMod);
    const timerDuration = Duration(milliseconds: 500);
    Timer(
        timerDuration,
        () => Navigator.of(context).pushReplacement(
            //MaterialPageRoute(builder: (BuildContext context) =>
            PageTransition(
                widget: batteryDetails,
                tranType: 'animatedopacity',
                tranDuration: 600)
            //, fullscreenDialog: true)
            ));
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = Theme.of(context).primaryColor;
    return Scaffold(
        backgroundColor: bgColor,
        body: StreamBuilder(
            initialData: 0.0,
            stream: periodicStream,
            builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
              debugPrint('SplashScreen >> $snapshot');
              if (snapshot.hasData) {
                //final progressValue = snapshot.data;
                return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(color: bgColor),
                      ),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 40.0,
                                        child: Container(
                                            decoration: BoxDecoration(
                                          image: DecorationImage(
                                            colorFilter: ColorFilter.mode(
                                                bgColor, BlendMode.overlay),
                                            image: AssetImage(
                                                "images/batteryalert.png"),
                                            fit: BoxFit.cover,
                                          ),
                                        ))),
                                    Padding(
                                        padding: EdgeInsets.only(top: 10.0)),
                                    Hero(
                                      tag: 'heroAppTitle',
                                      child: Text(bMod.appTitle!,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24.0,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ].toList(),
                                ),
                              ),
                            ),
                            // Expanded(
                            //   flex:1,
                            //   child:Column(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     children: <Widget>[
                            //       CircularProgressIndicator(value: progressValue, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            //       Padding(
                            //         padding: EdgeInsets.only(top: 10.0)
                            //       ),
                            //       Text(
                            //         'loading',
                            //         style: TextStyle(
                            //           color: Colors.white,
                            //           fontSize: 24.0,
                            //           fontWeight: FontWeight.bold
                            //         ),
                            //       )
                            //     ].where((o) => o != null).toList()
                            //   ),
                            // ),
                          ].toList())
                    ].toList());
              } else {
                return Container(
                    child: Text(
                  'loading',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold),
                ));
              }
            }));
  }

  @override
  void dispose() {
    super.dispose();
    periodicSubscription.cancel();
    //periodicSubscription = null;
    //periodicStream = null;
    periodicController.close();
    //periodicController = null;
  }
}
