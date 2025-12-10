import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/core/widgets/app_shell.dart';

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
                        style: AppTextStyles.initWorldSubtitle,
                      ),
                      SizedBox(
                        width: iconDiameter,
                        height: iconDiameter * 1.0,
                        child: OverflowBox(
                          maxWidth: iconDiameter * 1.2,
                          minWidth: iconDiameter * 1.2,
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
                    ],
                  ),
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLarge,
                    0,
                    AppSizes.paddingLarge,
                    AppSizes.paddingLarge,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF000000), // Negro
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
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    fontSize: 13,
                                    fontFamily: 'TikTokSans',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 2,
        onItemTapped: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => AppShell(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
    );
  }
}
