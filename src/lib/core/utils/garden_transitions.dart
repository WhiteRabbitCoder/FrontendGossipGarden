import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class GardenTransitions {
  static Route<T> sharedAxis<T>(Widget page, {SharedAxisTransitionType type = SharedAxisTransitionType.horizontal}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }

  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }
}
