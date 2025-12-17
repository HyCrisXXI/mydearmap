import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';

class InitWorldView extends StatefulWidget {
  const InitWorldView({super.key, this.userName, this.onEnterWorld});

  final String? userName;
  final VoidCallback? onEnterWorld;

  @override
  State<InitWorldView> createState() => _InitWorldViewState();
}

class _InitWorldViewState extends State<InitWorldView>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  late final AnimationController _controller;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _iconScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToMap() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    widget.onEnterWorld?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double iconDiameter = size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(AppIcons.initWorldBG, fit: BoxFit.cover),
          ),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 125, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Content Group (Text)
                      FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Column(
                            children: [
                              Text(
                                'MyDearMap',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.myDearMapTitle,
                              ),
                              const SizedBox(height: 13),
                              Text(
                                'Because every memory\ndeserves a place',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.textButton,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Icon with Scale Animation
                      ScaleTransition(
                        scale: _iconScaleAnimation,
                        child: SizedBox(
                          width: iconDiameter,
                          height: iconDiameter * 1.0,
                          child: OverflowBox(
                            maxWidth: iconDiameter * 1.1,
                            minWidth: iconDiameter * 1.1,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            alignment: Alignment.topCenter,
                            child: Image.asset(
                              AppIcons.initWorld,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Button Group
                      FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Align(
                            alignment: Alignment.center,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF000000),
                                foregroundColor: Colors.white,
                                fixedSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _isNavigating ? null : _goToMap,
                              child: _isNavigating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.5,
                                        fontSize: 14,
                                        fontFamily: 'TikTokSans',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
