import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'timecapsule_view.dart';
import 'timecapsule_create_view.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/relations/views/relations_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TimeCapsulesView extends ConsumerWidget {
  const TimeCapsulesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(userTimeCapsulesProvider);

    return capsulesAsync.when(
      loading: () => const _TimeCapsulesLayout(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          _TimeCapsulesLayout(child: Center(child: Text('Error: $error'))),
      data: (capsules) => _TimeCapsulesLayout(
        onAddPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TimeCapsuleCreateView()),
          );
        },
        child: capsules.isEmpty
            ? const Center(child: Text('No tienes cápsulas de tiempo.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: capsules.length,
                itemBuilder: (context, index) {
                  final capsule = capsules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(capsule.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (capsule.description != null)
                            Text(capsule.description!),
                          Text('Días para abrir: ${capsule.daysUntilOpen}'),
                          Text(capsule.isClosed ? 'Cerrada' : 'Abierta'),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TimeCapsuleView(capsuleId: capsule.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _TimeCapsulesLayout extends StatelessWidget {
  const _TimeCapsulesLayout({required this.child, this.onAddPressed});

  final Widget child;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.upperPadding,
                bottom: 8.0,
                left: 16,
                right: 30.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: SvgPicture.asset(AppIcons.chevronLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppButtonStyles.circularIconButton,
                    ),
                  ),
                  const Text(
                    'Mis Cápsulas de Tiempo',
                    style: AppTextStyles.title,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            AppIcons.timer,
                            colorFilter: const ColorFilter.mode(
                              AppColors.blue,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          style: AppButtonStyles.circularIconButton,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: SvgPicture.asset(AppIcons.heartHandshake),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RelationsView(),
                              ),
                            );
                          },
                          style: AppButtonStyles.circularIconButton,
                        ),
                        if (onAddPressed != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: SvgPicture.asset(AppIcons.plus),
                            onPressed: onAddPressed,
                            style: AppButtonStyles.circularIconButton,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
