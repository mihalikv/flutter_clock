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

enum _Element { background, text, shadow, animationAsset }

final _lightTheme = {
  _Element.background: Colors.white,
  _Element.text: Colors.black,
  _Element.shadow: Colors.black,
  _Element.animationAsset: "assets/export.flr",
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFF174EA6),
};

final _numberAnimationOrder = {
  0: "zeroToOne",
  1: "oneToTwo",
//  2: "twoToThree",
//  3: "threeToFour",
//  4: "fourToFive",
//  5: "fiveToSix",
//  6: "sixToSeven",
//  7: "sevenToEight",
//  8: "eightToNine",
//  9: "nineToZero",
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

class _DigitalClockState extends State<DigitalClock> with FlareController {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  double _digitTime = 0.0;
  double _animationSpeedRatio = 1;
  double stopTime = 2;
  int _counter = 0;

  final List<FlareAnimationLayer> _digitAnimations = [];
  ActorAnimation _digit;
  FlareAnimationLayer current_layer;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _counter = 0;
    for (var entry in _numberAnimationOrder.entries) {
      _digitAnimations.add(FlareAnimationLayer()..animation = artboard.getAnimation(entry.value));
    }
    current_layer = _digitAnimations[0];
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (stopTime > 0) {
      stopTime -= elapsed;
      return true;
    }
    _digitTime += elapsed * _animationSpeedRatio;
    current_layer.time = _digitTime;
    current_layer.mix = 1;
    if (current_layer.isDone) {
      current_layer.apply(artboard);
      _counter = (_counter + 1) % _digitAnimations.length;
      current_layer = _digitAnimations[_counter];
      _digitTime = 0;
      stopTime = 2;
      return true;
    }

    current_layer.apply(artboard);
    return true;
  }

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
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);

    return Container(
      color: colors[_Element.background],
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <
          Widget>[
        Expanded(
          child: FlareActor(
            colors[_Element.animationAsset],
            controller: this,
            snapToEnd: true,
          ),
        ),
//        Expanded(
//          child: FlareActor(colors[_Element.animationAsset], controller: this),
//        ),
//        Expanded(
//            child: Row(
//          children: <Widget>[
//            Expanded(
//              child:
//                  FlareActor(colors[_Element.animationAsset], controller: this),
//            ),
//            Expanded(
//              child:
//                  FlareActor(colors[_Element.animationAsset], controller: this),
//            ),
//          ],
//          mainAxisAlignment: MainAxisAlignment.center,
//        )),
//        Expanded(
//          child: FlareActor(colors[_Element.animationAsset], controller: this),
//        ),
//        Expanded(
//          child: FlareActor(
//            colors[_Element.animationAsset],
//            animation: "zeroToOne",
//          ),
//        )
      ]),
    );
  }
}
