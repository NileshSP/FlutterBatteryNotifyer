import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'SplashScreen.dart';

final String appTitle = 'Battery Notifier';
void main() => runApp(MaterialApp(
      title: appTitle,
      theme: ThemeData(
          primaryColor: Colors.redAccent,
          accentColor: Colors.blueAccent,
          backgroundColor: Colors.transparent,
          scaffoldBackgroundColor: Colors.transparent),
      debugShowCheckedModeBanner: false,
      home: AudioServiceWidget(child: SplashScreen(title: appTitle)),
    ));
