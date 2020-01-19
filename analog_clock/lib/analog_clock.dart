// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum _Theme {
  background,
}

final weatherThemeMapping = {
  WeatherCondition.cloudy: {
    _Theme.background: ["assets/cloudy.jpg", "assets/cloudy2.jpg"],
  },
  WeatherCondition.foggy: {
    _Theme.background: ["assets/fog.jpg"],
  },
  WeatherCondition.rainy: {
    _Theme.background: ["assets/rainy.jpg"],
  },
  WeatherCondition.snowy: {
    _Theme.background: ["assets/snowy.jpg"],
  },
  WeatherCondition.sunny: {
    _Theme.background: ["assets/sunny.jpg", "assets/sunny2.jpg"],
  },
  WeatherCondition.thunderstorm: {
    _Theme.background: ["assets/thunderstorm.jpg", "assets/thunderstorm2.jpg"],
  },
  WeatherCondition.windy: {
    _Theme.background: ["assets/windy.jpg"],
  }
};

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;
  AssetImage _bgImage;
  final _random = new Random();

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
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
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '${widget.model.low} - ${widget.model.highString}';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
      _bgImage = AssetImage(
        weatherThemeMapping[widget.model.weatherCondition][_Theme.background][
            _random.nextInt(
                weatherThemeMapping[widget.model.weatherCondition].length)],
      );
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(milliseconds: 1) - Duration(microseconds: _now.microsecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF50514F),
            backgroundColor: Color(0xFFFDFFF7),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    final descriptionStyle = new TextStyle(
      fontWeight: FontWeight.bold,
      height: 2
    );
    final valueStyle = GoogleFonts.arbutus(
      fontSize: 25,
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(image: _bgImage, fit: BoxFit.cover)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              alignment: AlignmentDirectional.center,
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  painter: PathPainter(_now),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/watch.png',
                    fit: BoxFit.fitHeight,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    Container(
                        decoration: BoxDecoration(
                            color: customTheme.backgroundColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        padding: EdgeInsets.all(10),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: new TextStyle(
                              color: customTheme.accentColor,
                            ),
                            children: <TextSpan>[
                              new TextSpan(
                                  text:
                                      DateFormat('dd. MM. yyyy\n').format(_now),
                                  style: valueStyle),
                              new TextSpan(
                                  text: 'Temperature\n',
                                  style: descriptionStyle),
                              new TextSpan(
                                  text: _temperatureRange, style: valueStyle),
                            ],
                          ),
                        )),
                  ],
                )
              ],
            ),
          )),
    );
  }
}

class PathPainter extends CustomPainter {
  DateTime _now;
  final radiansPerTick = (2 * pi) / 60000;

  PathPainter(this._now);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Color(0xffa5d6ff)
      ..style = PaintingStyle.fill;

    Offset center = Offset(size.height / 2, size.height / 2);
    Rect rect = Rect.fromCircle(center: center, radius: size.height / 2);
    var startAngle = 1.5 * pi;
    var endAngle = radiansPerTick * ((_now.second * 1000) + _now.millisecond);
    Path path = Path();
    path.moveTo(center.dx, center.dy);
    if (_now.minute % 2 == 0) {
      var tmpStartAngle = startAngle;
      var tmpEndAngle = endAngle;
      startAngle = (tmpStartAngle + tmpEndAngle) % (2 * pi);
      endAngle = (2 * pi) - (startAngle - (1.5 * pi));
    }

    if (endAngle % (2 * pi) == 0) {
      path.addArc(rect, startAngle, endAngle);
    } else {
      path.arcTo(rect, startAngle, endAngle, false);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class Clipper extends CustomClipper<Path> {
  DateTime _now;
  final radiansPerTick = (2 * pi) / 60000;

  Clipper(this._now);

  @override
  Path getClip(Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    Rect rect = Rect.fromCircle(center: center, radius: size.height / 2);
    var startAngle = 1.5 * pi;
    var endAngle = radiansPerTick * ((_now.second * 1000) + _now.millisecond);
    Path path = Path();
    path.moveTo(center.dx, center.dy);
    if (_now.minute % 2 == 0) {
      var tmpStartAngle = startAngle;
      var tmpEndAngle = endAngle;
      startAngle = (tmpStartAngle + tmpEndAngle) % (2 * pi);
      endAngle = (2 * pi) - (startAngle - (1.5 * pi));
    }

    if (endAngle % (2 * pi) == 0) {
      path.addArc(rect, startAngle, endAngle);
    } else {
      path.arcTo(rect, startAngle, endAngle, false);
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
