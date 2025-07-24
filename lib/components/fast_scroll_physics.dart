import 'package:flutter/material.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const UltraSnappyScrollPhysics();
  }
}

class UltraSnappyScrollPhysics extends ScrollPhysics {
  const UltraSnappyScrollPhysics({ScrollPhysics? parent})
    : super(parent: parent);

  @override
  UltraSnappyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return UltraSnappyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (velocity.abs() < tolerance.velocity) return null;

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: 0, // Extremely low momentum
      friction: 1, // High friction = stops quickly
      tolerance: tolerance,
    );
  }
}
