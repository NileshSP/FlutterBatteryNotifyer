import 'dart:async';
import 'dart:convert';
import 'package:battery/battery.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryModel {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  BatteryState currBatteryState, notifyBatteryState;
  int currBatteryLevel, notifyBatteryLevel;
  DateTime? currBatteryDateTime;
  String? appTitle;
  Color backgroundColor, frontTextColor;

  BatteryModel({
    this.appTitle,
    this.currBatteryState = BatteryState.charging,
    this.currBatteryLevel = 0,
    this.currBatteryDateTime,
    this.notifyBatteryState = BatteryState.full,
    this.notifyBatteryLevel = 100,
    this.backgroundColor = Colors.greenAccent,
    this.frontTextColor = Colors.black,
  });

  getBatteryStateDisplayValue(
      {BatteryState batteryStateVal: BatteryState.full}) {
    final stateVal = batteryStateVal
        .toString()
        .substring(batteryStateVal.toString().indexOf('.') + 1);
    return stateVal[0].toUpperCase() + stateVal.substring(1);
  }

  BatteryModel fromJson(Map<String, dynamic> json) {
    appTitle = json['appTitle'];
    currBatteryState = getBatteryStatefromString(json['currBatteryState']);
    currBatteryLevel =
        int.tryParse(json['currBatteryLevel']) ?? currBatteryLevel;
    currBatteryDateTime =
        DateTime.tryParse(json['currBatteryDateTime']) ?? currBatteryDateTime;
    notifyBatteryState = getBatteryStatefromString(json['notifyBatteryState']);
    notifyBatteryLevel =
        int.tryParse(json['notifyBatteryLevel']) ?? notifyBatteryLevel;
    backgroundColor = Color(int.parse(json['backgroundColor']));
    frontTextColor = Color(int.parse(json['frontTextColor']));
    return this;
  }

  BatteryState getBatteryStatefromString(String? jsonKey) {
    if (jsonKey == 'BatteryState.full')
      return BatteryState.full;
    else if (jsonKey == 'BatteryState.discharging')
      return BatteryState.discharging;
    else
      return BatteryState.charging;
  }

  Map<String, dynamic> toJsonList() => {
        'appTitle': appTitle,
        'currBatteryState': currBatteryState.toString(),
        'currBatteryLevel': currBatteryLevel.toString(),
        'currBatteryDateTime': currBatteryDateTime.toString(),
        'notifyBatteryState': notifyBatteryState.toString(),
        'notifyBatteryLevel': notifyBatteryLevel.toString(),
        'backgroundColor': backgroundColor.value.toString(),
        'frontTextColor': frontTextColor.value.toString()
      };

  Future<String> toJson() async {
    return JsonEncoder.withIndent(' ').convert(this.toJsonList());
  }

  storeValuesToBePersisted() async {
    try {
      final SharedPreferences sPrefs = await prefs;
      final objVal = await toJson();
      sPrefs.setString('currentUserDetails', objVal);
      debugPrint('Values successfully persisted to disk!!');
    } catch (e) {
      debugPrint('Error caused while storing values: $e');
    }
  }

  getPersistedValues() async {
    try {
      final SharedPreferences sPrefs = await prefs;
      final String? objVal = sPrefs.getString('currentUserDetails');
      if (objVal != null) {
        // debugPrint('string from disk' + objVal);
        // debugPrint('decoded json from disk' + Map.from(json.decode(objVal)).toString());
        this.fromJson(Map.from(json.decode(objVal)));
      }
    } catch (e) {
      debugPrint('Error caused while getting persisted values: $e');
    } finally {
      //debugPrint('Final values from disk attached to object are : ' + await this.toJson());
    }
  }

  bool get isInDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}
