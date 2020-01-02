// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'utils/curves.dart';

/// An in-place fade and scale transition used by [PageTransitionsTheme]
/// to create a page transition with [SharedZAxisTransition].
///
/// The shared axis pattern provides the transition animation
/// between UI elements that have a spatial or navigational
/// relationship. For example, transitioning from one page of a
/// sign-up page to the next one.
///
/// In this particular transition, the outgoing widget expands and
/// fades away while the incoming widget shrinks and fades into place.
///
/// The following example shows how the SharedZAxisPageTransitionsBuilder can
/// be used in a [PageTransitionsTheme] to change the default transitions
/// of [MaterialPageRoute]s.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: SharedZAxisPageTransitionsBuilder(),
///         TargetPlatform.iOS: SharedZAxisPageTransitionsBuilder(),
///       },
///     ),
///   ),
///   routes: {
///     '/': (BuildContext context) {
///       return Container(
///         color: Colors.red,
///         child: Center(
///           child: MaterialButton(
///             child: Text('Push route'),
///             onPressed: () {
///               Navigator.of(context).pushNamed('/a');
///             },
///           ),
///         ),
///       );
///     },
///     '/a': (BuildContext context) {
///       return Container(
///         color: Colors.blue,
///         child: Center(
///           child: RaisedButton(
///             child: Text('Pop route'),
///             onPressed: () {
///               Navigator.of(context).pop();
///             },
///           ),
///         ),
///       );
///     },
///   },
/// );
/// ```
class SharedZAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Construct a [SharedZAxisPageTransitionsBuilder].
  const SharedZAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedZAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Defines a in-place transition in which the outgoing widget expands
/// and fades away while the incoming widget shrinks and fades into place.
///
/// The shared axis pattern provides the transition animation between UI elements
/// that have a spatial or navigational relationship. For example,
/// transitioning from one page of a sign-up page to the next one.
///
/// Consider using [SharedZAxisTransition] within a
/// [PageTransitionsTheme] if you want to apply this kind of transition to
/// all [MaterialPageRoute] transitions within a Navigator (see
/// [SharedZAxisPageTransitionsBuilder] for some example code).
///
/// This transition can also be used directly in a
/// [PageTransitionSwitcher.transitionBuilder] to transition
/// from one widget to another as seen in the following example:
/// ```dart
/// int _selectedIndex = 0;
///
/// final List<Color> _colors = [Colors.white, Colors.red, Colors.yellow];
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('Page Transition Example'),
///     ),
///     body: PageTransitionSwitcher(
///       // reverse: true, // uncomment to see transition in reverse
///       transitionBuilder: (
///         Widget child,
///         Animation<double> primaryAnimation,
///         Animation<double> secondaryAnimation,
///       ) {
///         return SharedZAxisTransition(
///           animation: primaryAnimation,
///           secondaryAnimation: secondaryAnimation,
///           child: child,
///         );
///       },
///       child: Container(
///         key: ValueKey<int>(_selectedIndex),
///         color: _colors[_selectedIndex],
///         child: Center(
///           child: FlutterLogo(size: 300),
///         )
///       ),
///     ),
///     bottomNavigationBar: BottomNavigationBar(
///       items: const <BottomNavigationBarItem>[
///         BottomNavigationBarItem(
///           icon: Icon(Icons.home),
///           title: Text('White'),
///         ),
///         BottomNavigationBarItem(
///           icon: Icon(Icons.business),
///           title: Text('Red'),
///         ),
///         BottomNavigationBarItem(
///           icon: Icon(Icons.school),
///           title: Text('Yellow'),
///         ),
///       ],
///       currentIndex: _selectedIndex,
///       onTap: (int index) {
///         setState(() {
///           _selectedIndex = index;
///         });
///       },
///     ),
///   );
/// }
/// ```
class SharedZAxisTransition extends StatefulWidget {
  /// Creates a [SharedZAxisTransition].
  ///
  /// The [animation] and [secondaryAnimation] arguments are required and must
  /// not be null.
  const SharedZAxisTransition({
    Key key,
    @required this.animation,
    @required this.secondaryAnimation,
    this.child,
  })  : assert(animation != null),
        assert(secondaryAnimation != null),
        super(key: key);

  /// The animation that drives the [child]'s entrance and exit.
  ///
  /// See also:
  ///
  ///  * [TransitionRoute.animate], which is the value given to this property
  ///    when it is used as a page transition.
  final Animation<double> animation;

  /// The animation that transitions [child] when new content is pushed on top
  /// of it.
  ///
  /// See also:
  ///
  ///  * [TransitionRoute.secondaryAnimation], which is the value given to this
  ///    property when the it is used as a page transition.
  final Animation<double> secondaryAnimation;

  /// The widget below this widget in the tree.
  ///
  /// This widget will transition in and out as driven by [animation] and
  /// [secondaryAnimation].
  final Widget child;

  @override
  _SharedZAxisTransitionState createState() => _SharedZAxisTransitionState();
}

class _SharedZAxisTransitionState extends State<SharedZAxisTransition> {
  AnimationStatus _effectiveAnimationStatus;
  AnimationStatus _effectiveSecondaryAnimationStatus;

  @override
  void initState() {
    super.initState();
    _effectiveAnimationStatus = widget.animation.status;
    _effectiveSecondaryAnimationStatus = widget.secondaryAnimation.status;
    widget.animation.addStatusListener(_animationListener);
    widget.secondaryAnimation.addStatusListener(_secondaryAnimationListener);
  }

  void _animationListener(AnimationStatus animationStatus) {
    _effectiveAnimationStatus = _calculateEffectiveAnimationStatus(
      lastEffective: _effectiveAnimationStatus,
      current: animationStatus,
    );
  }

  void _secondaryAnimationListener(AnimationStatus animationStatus) {
    _effectiveSecondaryAnimationStatus = _calculateEffectiveAnimationStatus(
      lastEffective: _effectiveSecondaryAnimationStatus,
      current: animationStatus,
    );
  }

  // When a transition is interrupted midway we just want to play the ongoing
  // animation in reverse. Switching to the actual reverse transition would
  // yield a disjoint experience since the forward and reverse transitions are
  // very different.
  AnimationStatus _calculateEffectiveAnimationStatus({
    @required AnimationStatus lastEffective,
    @required AnimationStatus current,
  }) {
    assert(current != null);
    assert(lastEffective != null);
    switch (current) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        return current;
      case AnimationStatus.forward:
        switch (lastEffective) {
          case AnimationStatus.dismissed:
          case AnimationStatus.completed:
          case AnimationStatus.forward:
            return current;
          case AnimationStatus.reverse:
            return lastEffective;
        }
        break;
      case AnimationStatus.reverse:
        switch (lastEffective) {
          case AnimationStatus.dismissed:
          case AnimationStatus.completed:
          case AnimationStatus.reverse:
            return current;
          case AnimationStatus.forward:
            return lastEffective;
        }
        break;
    }
    return null; // unreachable
  }

  void _updateAnimationListener(
    Animation<double> oldAnimation,
    Animation<double> animation,
  ) {
    if (oldAnimation != animation) {
      oldAnimation.removeStatusListener(_animationListener);
      animation.addStatusListener(_animationListener);
      _animationListener(animation.status);
    }
  }

  @override
  void didUpdateWidget(SharedZAxisTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationListener(
      oldWidget.animation,
      widget.animation,
    );
    _updateAnimationListener(
      oldWidget.secondaryAnimation,
      widget.secondaryAnimation,
    );
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_animationListener);
    widget.secondaryAnimation.removeStatusListener(_secondaryAnimationListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Tween<double> flippedTween = Tween<double>(
      begin: 1.0,
      end: 0.0,
    );

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget child) {
        assert(_effectiveAnimationStatus != null);
        switch (_effectiveAnimationStatus) {
          case AnimationStatus.forward:
            return _EnterTransition(
              animation: widget.animation,
              child: child,
            );
          case AnimationStatus.dismissed:
          case AnimationStatus.reverse:
          case AnimationStatus.completed:
            return _ExitTransition(
              animation: flippedTween.animate(
                widget.animation,
              ),
              child: child,
            );
        }
        return null; // unreachable
      },
      child: AnimatedBuilder(
        animation: widget.secondaryAnimation,
        builder: (BuildContext context, Widget child) {
          assert(_effectiveSecondaryAnimationStatus != null);
          switch (_effectiveSecondaryAnimationStatus) {
            case AnimationStatus.forward:
              return _ExitTransition(
                animation: widget.secondaryAnimation,
                child: child,
              );
            case AnimationStatus.dismissed:
            case AnimationStatus.reverse:
            case AnimationStatus.completed:
              return _EnterTransition(
                animation: flippedTween.animate(
                  widget.secondaryAnimation,
                ),
                child: child,
              );
          }
          return null; // unreachable
        },
        child: widget.child,
      ),
    );
  }
}

class _EnterTransition extends StatelessWidget {
  const _EnterTransition({
    this.animation,
    this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static Animatable<double> fadeInTransition = CurveTween(
    curve: decelerateEasing,
  ).chain(CurveTween(curve: const Interval(0.3, 1.0)));

  static Animatable<double> scaleInTransition = Tween<double>(
    begin: 0.80,
    end: 1.00,
  ).chain(CurveTween(curve: standardEasing));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeInTransition.animate(animation),
      child: ScaleTransition(
        scale: scaleInTransition.animate(animation),
        child: child,
      ),
    );
  }
}

class _ExitTransition extends StatelessWidget {
  const _ExitTransition({
    this.animation,
    this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static Animatable<double> fadeOutTransition = FlippedCurveTween(
    curve: accelerateEasing,
  ).chain(CurveTween(curve: const Interval(0.0, 0.3)));

  static Animatable<double> scaleOutTransition = Tween<double>(
    begin: 1.00,
    end: 1.10,
  ).chain(CurveTween(curve: standardEasing));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeOutTransition.animate(animation),
      child: Container(
        color: Theme.of(context).canvasColor,
        child: ScaleTransition(
          scale: scaleOutTransition.animate(animation),
          child: child,
        ),
      ),
    );
  }
}
