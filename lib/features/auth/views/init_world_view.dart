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
                      SizedBox(
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
                      const SizedBox(height: 50),
                      Align(
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
