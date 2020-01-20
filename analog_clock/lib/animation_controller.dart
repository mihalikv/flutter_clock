import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_controller.dart';

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

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    final animationTime = DateTime.now().minute * 60.0;
    _element.apply(animationTime, artboard, 1);
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
