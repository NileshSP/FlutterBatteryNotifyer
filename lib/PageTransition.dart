import 'package:flutter/material.dart';

class PageTransition extends PageRouteBuilder {
  final Widget widget;
  final String tranType;
  int tranDuration = 1000;

  PageTransition({this.widget, this.tranType, this.tranDuration})
    : super(
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return widget;
        },
        transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
          if(tranType == null || tranType == 'fade') {
            return FadeTransition(
              child: child,
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation)
            );
          }
          else if(tranType == 'slide') {  
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
             );
          }
          else if(tranType == 'crossfade') { 
            bool firstStateEnabled = false;
            return AnimatedCrossFade(
              firstChild: Container(),
              secondChild: child,
              crossFadeState: firstStateEnabled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: Duration(milliseconds: tranDuration)
             );
          }
          else if(tranType == 'animatedopacity') { 
            return AnimatedOpacity(
              child: child,
              opacity: 1.0,
              duration: Duration(milliseconds: tranDuration)
             );
          }
          return null;
        },
        transitionDuration: Duration(milliseconds: tranDuration),
      );

  @override
  void dispose() {
    super.dispose();
  }
}