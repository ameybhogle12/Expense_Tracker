import 'package:flutter/material.dart';

/// A smooth slide + fade page route transition used throughout the app.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
        );
}

/// A staggered list item animation widget.
/// Wraps a child and animates it sliding up + fading in.
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Animation<double> controller;
  final int totalItems;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    required this.controller,
    this.totalItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    final begin = (index / totalItems).clamp(0.0, 0.9);
    final end = ((index + 1) / totalItems).clamp(0.1, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Animated balance bar that smoothly grows to its target value.
class AnimatedBalanceBar extends StatelessWidget {
  final double ratio;
  final bool isPositive;
  final Color backgroundColor;
  final Color barColor;

  const AnimatedBalanceBar({
    super.key,
    required this.ratio,
    required this.isPositive,
    required this.backgroundColor,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        );
      },
    );
  }
}

/// Animated counter that smoothly counts up to a target number.
class AnimatedCounter extends StatelessWidget {
  final double targetValue;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '$prefix${value.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}
