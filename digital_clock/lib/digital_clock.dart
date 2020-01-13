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
        ((DateTime
            .now()
            .second * 1000) + DateTime
            .now()
            .millisecond) / 1000;
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
    final animationTime = DateTime
        .now()
        .minute * 60.0;
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
    final animationTime = ((DateTime
        .now()
        .hour % 12) * 60.0 * 60.0) +
        (DateTime
            .now()
            .minute * 60.0);
    _element.apply(animationTime, artboard, 1);
    return true;
  }
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  AssetImage _bgImage;

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
      if (widget.model.weatherCondition == WeatherCondition.sunny) {
        this._bgImage = AssetImage('assets/bg_summer.png');
      } else {
        this._bgImage = AssetImage('assets/bg_winter.png');
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
    final colors = Theme
        .of(context)
        .brightness == Brightness.light
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
        FlareActor("assets/Cloud.flr",
            alignment: Alignment.topLeft,
            fit: BoxFit.contain,
            animation: "Main"),
        Container(
          alignment: Alignment.center,
          child: Image.asset("assets/face.png"),
        ),
        FlareActor("assets/Second.flr",
            alignment: Alignment.center,
            fit: BoxFit.contain,
            controller: TickController("Main")),
        FlareActor("assets/Minute.flr",
            alignment: Alignment.center,
            fit: BoxFit.contain,
            controller: MinuteController("Main")),
        FlareActor("assets/Hour.flr",
            alignment: Alignment.center,
            fit: BoxFit.contain,
            controller: HourController("Main")),


      ]),
    );
  }
}
