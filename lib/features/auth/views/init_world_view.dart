import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';

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
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLarge,
                AppSizes.upperPadding + 40,
                AppSizes.paddingLarge,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MyDearMap',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Because every memory\ndeserves a place',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: iconDiameter,
                  height: iconDiameter * 1.1,
                  child: Image.asset(
                    AppIcons.initWorld,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLarge,
                AppSizes.paddingLarge,
                AppSizes.paddingLarge,
                AppSizes.paddingLarge,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60),
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
                                fontSize: 20,
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
      bottomNavigationBar: const AppNavBar(currentIndex: 2),
    );
  }
}
