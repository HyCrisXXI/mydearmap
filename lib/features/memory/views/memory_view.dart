// lib/features/memory/views/memory_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/memory_controller.dart';
import '../../../data/models/memory.dart';
import '../../../core/constants/constants.dart';
import '../../../core/errors/memory_errors.dart';

class MemoryView extends ConsumerWidget {
  final String memoryId;

  const MemoryView({super.key, required this.memoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryState = ref.watch(memoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Memory Details"),
        backgroundColor: AppColors.primaryColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: memoryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (_) => _MemoryDetails(memoryId: memoryId),
        error: (error, stack) {
          String message = "Ocurrió un error";
          if (error is MemoryException) {
            message = error.message;
          }
          return Center(
            child: Text(
              message,
              style: TextStyle(color: AppColors.orange, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}

class _MemoryDetails extends ConsumerWidget {
  final String memoryId;

  const _MemoryDetails({required this.memoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Memory?>(
      future: ref.read(memoryControllerProvider.notifier).getMemoryById(memoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          String message = "Ocurrió un error";
          if (snapshot.error is MemoryException) {
            message = (snapshot.error as MemoryException).message;
          }
          return Center(
            child: Text(
              message,
              style: TextStyle(color: AppColors.orange, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final memory = snapshot.data;
        if (memory == null) {
          return Center(
            child: Text(
              "Memory no encontrada",
              style: TextStyle(color: AppColors.orange, fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: ListView(
            children: [
              Text(
                memory.title,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (memory.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
                  child: Text(
                    memory.description!,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              Text(
                "Fecha: ${memory.happenedAt.toLocal()}".split(' ')[0],
                style: TextStyle(fontSize: 14, color: AppColors.textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Reacciones
              Card(
                color: AppColors.cian.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reacciones (${memory.reactions.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      for (var reaction in memory.reactions)
                        Text("${reaction.user.name}: ${reaction.reactionType}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Comentarios
              Card(
                color: AppColors.yellow.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Comentarios (${memory.comments.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      for (var comment in memory.comments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentColor,
                            child: Text(comment.user.name[0]),
                          ),
                          title: Text(comment.user.name),
                          subtitle: Text(comment.content),
                          trailing: Text(
                            "${comment.createdAt.toLocal()}".split(' ')[0],
                            style: TextStyle(fontSize: 12, color: AppColors.textColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
