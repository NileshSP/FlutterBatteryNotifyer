import 'dart:async';

import 'package:flutter/material.dart';
import 'package:battery/battery.dart';
import 'BatteryModel.dart';
import 'package:numberpicker/numberpicker.dart';

class NotificationTriggers extends StatefulWidget {
  final BatteryModel batMod;

  NotificationTriggers(this.batMod);
  
  @override
  NotificationTriggersState createState() => NotificationTriggersState();
}

class NotificationTriggersState extends State<NotificationTriggers> {
  NumberPicker integerNumberPicker;
  List<BatteryState> listBatteryStates;
  BatteryModel bMod; 
  double opacityValue = 0.0;
  Timer timerInstance;

  @override
  void initState() {
    super.initState();
    bMod = widget.batMod;
    listBatteryStates = List<BatteryState>();
    listBatteryStates.addAll(getBatteryStateList());
    bMod.notifyBatteryState = listBatteryStates.contains(bMod.notifyBatteryState) ? bMod.notifyBatteryState : listBatteryStates.first;
    timerInstance = Timer.periodic(Duration(seconds: 1), (instance) => instance.tick <= 5 ? setState(() => opacityValue = opacityValue == 0.0 ? 1.0 : 0.0) : null);
  }

  List<BatteryState> getBatteryStateList() => BatteryState.values.where(((BatteryState s) => ((s == BatteryState.discharging && bMod.isInDebugMode) || s != BatteryState.discharging) ? true : false)).toList();

  @override
  Widget build(BuildContext context) {
    final orientationState = MediaQuery.of(context).orientation == Orientation.portrait ? true : false;

    return Scaffold(
      backgroundColor: bMod.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10.0),
          child: Center(
            heightFactor: orientationState ? 1.3 : 0.9,
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,                                
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(20.0), 
                    child: Text('Notify @', style: TextStyle(color: bMod.frontTextColor, fontSize: 40.0)),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<BatteryState>(
                      value: bMod.notifyBatteryState,
                      hint: Center(child: Text('Select battery state')),
                      onChanged: (newValue) {
                        if(newValue != null) {
                          setState(() {
                            bMod.notifyBatteryState = newValue;
                            if(newValue == BatteryState.full && bMod.notifyBatteryLevel != 100) {
                               integerNumberPicker.animateInt(bMod.notifyBatteryLevel = 100);
                            }
                            bMod.storeValuesToBePersisted();
                          });
                        }  
                      },
                      items: listBatteryStates.map((BatteryState item) {
                        return DropdownMenuItem<BatteryState>(
                          value: item,
                          child: Text(
                            bMod.getBatteryStateDisplayValue(item),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).accentColor, fontSize: 25.0,),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0), 
                    child: Text('with', style: TextStyle(color: bMod.frontTextColor, fontSize: 40.0)),
                  ),
                  integerNumberPicker = NumberPicker.integer(
                    minValue: 1,
                    maxValue: 100,
                    step: 1,
                    itemExtent: 35.0,
                    initialValue: bMod.notifyBatteryLevel,
                    onChanged: (newValue) {
                      if(newValue != null) {
                        setState(() {
                          bMod.notifyBatteryLevel = newValue;
                          bMod.notifyBatteryState = (() {
                            if(newValue == 100) {
                              return BatteryState.full;
                            }
                            else if (newValue < 100 && bMod.notifyBatteryState == BatteryState.full) { 
                              return BatteryState.charging;
                            }
                            else { 
                              return bMod.notifyBatteryState;
                            }
                          })();
                        });
                        bMod.storeValuesToBePersisted();
                      }
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0), 
                    child: Text('%', style: TextStyle(color: bMod.frontTextColor, fontSize: 40.0)),
                  ),
                  Container(
                    //decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.blue, ), borderRadius: BorderRadius.all(Radius.circular(20))),
                    padding: EdgeInsets.all(24.0),
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds:500),
                      curve: Curves.easeInOut,
                      opacity: opacityValue,
                      child: Wrap(
                      alignment: WrapAlignment.center,
                      children : <Widget>[
                          Icon(Icons.dock, color: Colors.blue,),
                          Text("Dock /", style: TextStyle(fontSize: 18, color: Colors.black),),
                          Icon(Icons.lock_outline, color: Colors.blue,),
                          Text("Lock", style: TextStyle(fontSize: 18, color: Colors.black)),
                          Text("In device's recent app view list, kindly dock(pin)/lock the '"+ bMod.appTitle +"' app to continuously monitor the above settings while the app is not in use"
                          , style: TextStyle(fontSize: 16, color: Colors.black))
                        ]  
                      ),
                    )
                  )
                ]
              )
            )
          )
        ),
      ),  
      floatingActionButton: FloatingActionButton(
        heroTag: 'navTriggers',
        tooltip: 'Save battery STATE & LEVEL for notification',
        child: Icon(Icons.arrow_back, color: Colors.white,),
        backgroundColor: Theme.of(context).accentColor, 
        onPressed: () async {
          Navigator.of(context).pop();
        },
      ),
    );       
  }

  @override
  void dispose() {
    super.dispose();
    timerInstance?.cancel();
    timerInstance = null;
  }
}