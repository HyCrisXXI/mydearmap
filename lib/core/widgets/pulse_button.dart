import 'package:flutter/material.dart';

class PulseButton extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleFactor;

  const PulseButton({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 100),
    this.scaleFactor = 0.7,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _handleTapUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _handleTapCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleTapDown,
      onPointerUp: _handleTapUp,
      onPointerCancel: _handleTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
