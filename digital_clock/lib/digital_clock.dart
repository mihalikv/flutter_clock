// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:google_fonts/google_fonts.dart';

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _Element.shadow: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFF174EA6),
};

enum _Theme {
  background,
  animation,
}

final weatherThemeMapping = {
  WeatherCondition.cloudy: {
    _Theme.background: "assets/bg_cloudy.png",
    _Theme.animation: "assets/Cloudy.flr",
  },
  WeatherCondition.foggy: {
    _Theme.background: "assets/bg_cloudy.png",
    _Theme.animation: "assets/Foggy.flr",
  }
};

/// A basic digital clock.
///
/// You can do better than this!
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class TickController extends FlareController {
  ActorAnimation _element;
  String _animationName;

  TickController(String animationName) {
    this._animationName = animationName;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _element = artboard.getAnimation(this._animationName);
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    final animationTime =
        ((DateTime.now().second * 1000) + DateTime.now().millisecond) / 1000;
    _element.apply(animationTime, artboard, 1);
    return true;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}
}

class MinuteController extends TickController {
  MinuteController(String animationName) : super(animationName);

  ActorAnimation _elementSecondary;
  double animationTimeSecondary = 0;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _element = artboard.getAnimation(this._animationName);
    _elementSecondary = artboard.getAnimation('Wind');
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    final animationTime = DateTime.now().minute * 60.0;
    _element.apply(animationTime, artboard, 1);
    animationTimeSecondary += elapsed;
    animationTimeSecondary =
        animationTimeSecondary % _elementSecondary.duration;
    _elementSecondary.apply(animationTimeSecondary, artboard, 1);
    return true;
  }
}

class HourController extends TickController {
  HourController(String animationName) : super(animationName);

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    final animationTime = ((DateTime.now().hour % 12) * 60.0 * 60.0) +
        (DateTime.now().minute * 60.0);
    _element.apply(animationTime, artboard, 1);
    return true;
  }
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  AssetImage _bgImage;
  FlareActor _weatherAnimation;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
      if (weatherThemeMapping.containsKey(widget.model.weatherCondition)) {
        this._bgImage = AssetImage(
            weatherThemeMapping[widget.model.weatherCondition]
                [_Theme.background]);
        this._weatherAnimation = FlareActor(
            weatherThemeMapping[widget.model.weatherCondition]
                [_Theme.animation],
            alignment: Alignment.topLeft,
            fit: BoxFit.fitWidth,
            isPaused: false,
            animation: "Idle");
      } else {
        this._bgImage = AssetImage('assets/bg_summer.png');
        this._weatherAnimation = FlareActor(
            "assets/Cloud.flr",
            alignment: Alignment.topLeft,
            fit: BoxFit.fitWidth,
            isPaused: false,
            animation: "Idle");
      }
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
//      _timer = Timer(
//        Duration(minutes: 1) -
//            Duration(seconds: _dateTime.second) -
//            Duration(milliseconds: _dateTime.millisecond),
//        _updateTime,
//      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _bgImage,
          fit: BoxFit.contain,
        ),
      ),
      child: Stack(children: <Widget>[
        this._weatherAnimation,
        Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.all(20),
          child: Image.asset("assets/face.png"),
        ),
        Container(
          margin: EdgeInsets.all(20),
          child: FlareActor("assets/Second.flr",
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              controller: TickController("Main")),
        ),
        Container(
          margin: EdgeInsets.all(20),
          child: FlareActor("assets/Minute.flr",
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              controller: MinuteController("Main")),
        ),
        Container(
          margin: EdgeInsets.all(20),
          child: FlareActor("assets/Hour.flr",
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              controller: HourController("Main")),
        ),
        Positioned(
          right: 45,
          top: 85,
          height: 100,
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                child: Text(
                  widget.model.temperatureString,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 30,
                  ),
                ),
                padding: EdgeInsets.only(top: 10, right: 10),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Text(
                      widget.model.highString,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 18, color: Colors.red[400]),
                    ),
                    padding:
                        EdgeInsets.only(left: 8, right: 8, bottom: 6, top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2)),
                    ),
                  ),
                  Container(
                    child: Text(
                      widget.model.lowString,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 18, color: Colors.blue[400]),
                    ),
                    padding: EdgeInsets.all(8.0),
                  ),
                ],
              )
            ],
          ),
        )
      ]),
    );
  }
}
