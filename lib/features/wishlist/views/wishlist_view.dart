import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/wishlist_provider.dart';
import 'package:mydearmap/data/models/wishlist.dart';

class WishlistDialog extends ConsumerStatefulWidget {
  const WishlistDialog({super.key});

  @override
  ConsumerState<WishlistDialog> createState() => _WishlistDialogState();
}

class _WishlistDialogState extends ConsumerState<WishlistDialog> {
  final TextEditingController _titleController = TextEditingController();
  final Map<String, bool> _completionOverrides = <String, bool>{};
  final Set<String> _pendingCompletionWishlistIds = <String>{};
  final Set<String> _pendingRemovalWishlistIds = <String>{};
  final ScrollController _wishlistScrollController = ScrollController();
  bool _isSaving = false;

  @override
  void dispose() {
    _wishlistScrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistsAsync = ref.watch(userWishlistProvider);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Mi Wishlist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: wishlistsAsync.when(
                  data: (wishlists) => _WishlistList(
                    wishlists: wishlists,
                    completionResolver: _resolveWishlistCompletion,
                    pendingCompletionWishlists: _pendingCompletionWishlistIds,
                    pendingRemovalWishlists: _pendingRemovalWishlistIds,
                    scrollController: _wishlistScrollController,
                    onRefresh: _refreshWishlists,
                    onCreateTap: _handleCreateWishlist,
                    onToggleWishlist: _handleToggleCompletion,
                    onDeleteWishlist: _handleDeleteWishlist,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, _) => _WishlistError(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(userWishlistProvider),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              const Divider(),
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.grey),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          labelText: 'Añadir nuevo deseo... ',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: const BorderSide(
                              color: Colors.black26,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: const BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleCreateWishlist(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  SizedBox(
                    height: 46,
                    width: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textGray,
                        foregroundColor: AppColors.backgroundColor,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _isSaving ? null : _handleCreateWishlist,
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : SvgPicture.asset(
                                AppIcons.plus,
                                width: 30,
                                height: 30,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.backgroundColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshWishlists() async {
    ref.invalidate(userWishlistProvider);
    await ref.read(userWishlistProvider.future);
  }

  bool _resolveWishlistCompletion(Wishlist wishlist) {
    return _completionOverrides[wishlist.id] ?? wishlist.completed;
  }

  Future<String?> _requireUserId(String failureMessage) async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) return user.id;
    if (mounted) _showSnack(failureMessage);
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleToggleCompletion(Wishlist wishlist) async {
    if (_pendingCompletionWishlistIds.contains(wishlist.id)) return;

    final userId = await _requireUserId(
      'Inicia sesión para actualizar tus deseos.',
    );
    if (userId == null) return;

    final nextValue = !_resolveWishlistCompletion(wishlist);

    setState(() {
      _pendingCompletionWishlistIds.add(wishlist.id);
      _completionOverrides[wishlist.id] = nextValue;
    });

    var updateSucceeded = false;

    try {
      final repository = ref.read(wishlistRepositoryProvider);
      await repository.updateWishlistCompletion(
        wishlistId: wishlist.id,
        completed: nextValue,
      );

      await _refreshWishlists();
      updateSucceeded = true;
    } catch (error) {
      if (!mounted) return;
      _showSnack('No se pudo actualizar el deseo: $error');
      setState(() {
        _completionOverrides.remove(wishlist.id);
      });
    } finally {
      if (mounted) {
        setState(() {
          _pendingCompletionWishlistIds.remove(wishlist.id);
          if (updateSucceeded) {
            _completionOverrides.remove(wishlist.id);
          }
        });
      }
    }
  }

  Future<void> _handleDeleteWishlist(String wishlistId) async {
    if (_pendingRemovalWishlistIds.contains(wishlistId)) return;

    final userId = await _requireUserId(
      'Inicia sesión para poder eliminar tus deseos.',
    );
    if (userId == null) return;

    setState(() => _pendingRemovalWishlistIds.add(wishlistId));

    try {
      final repository = ref.read(wishlistRepositoryProvider);
      await repository.deleteWishlist(wishlistId: wishlistId);
      _completionOverrides.remove(wishlistId);
      _pendingCompletionWishlistIds.remove(wishlistId);
      await _refreshWishlists();

      if (!mounted) return;
      _showSnack('Deseo eliminado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('No se pudo eliminar el deseo: $error');
    } finally {
      if (mounted) {
        setState(() => _pendingRemovalWishlistIds.remove(wishlistId));
      }
    }
  }

  Future<void> _handleCreateWishlist() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Ingresa un título para tu deseo.');
      return;
    }

    if (_isSaving) return;

    final userId = await _requireUserId(
      'Inicia sesión para poder guardar tus deseos.',
    );
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(wishlistRepositoryProvider);
      await repository.createWishlist(userId: userId, title: title);

      _titleController.clear();
      await _refreshWishlists();

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _showSnack('Deseo guardado en tu lista.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('No se pudo guardar el deseo: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _WishlistList extends StatelessWidget {
  const _WishlistList({
    required this.wishlists,
    required this.completionResolver,
    required this.pendingCompletionWishlists,
    required this.pendingRemovalWishlists,
    required this.scrollController,
    required this.onRefresh,
    required this.onCreateTap,
    required this.onToggleWishlist,
    required this.onDeleteWishlist,
  });

  final List<Wishlist> wishlists;
  final bool Function(Wishlist wishlist) completionResolver;
  final Set<String> pendingCompletionWishlists;
  final Set<String> pendingRemovalWishlists;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateTap;
  final void Function(Wishlist wishlist) onToggleWishlist;
  final void Function(String wishlistId) onDeleteWishlist;

  @override
  Widget build(BuildContext context) {
    final visibleWishlists = wishlists
        .where((wishlist) => !pendingRemovalWishlists.contains(wishlist.id))
        .toList();

    if (visibleWishlists.isEmpty) {
      return _WishlistEmpty(onCreateTap: onCreateTap);
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: visibleWishlists.length,
          itemBuilder: (context, index) {
            final wishlist = visibleWishlists[index];
            final isCompleted = completionResolver(wishlist);
            final isUpdating = pendingCompletionWishlists.contains(wishlist.id);
            return _WishlistCard(
              wishlist: wishlist,
              isCompleted: isCompleted,
              isUpdatingCompletion: isUpdating,
              onToggle: () => onToggleWishlist(wishlist),
              onDelete: () => onDeleteWishlist(wishlist.id),
            );
          },
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.wishlist,
    required this.isCompleted,
    required this.isUpdatingCompletion,
    required this.onToggle,
    required this.onDelete,
  });

  final Wishlist wishlist;
  final bool isCompleted;
  final bool isUpdatingCompletion;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: AppColors.buttonDisabledBackground,
      surfaceTintColor: Colors.white,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3, horizontal: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: InkWell(
          onTap: isUpdatingCompletion ? null : onToggle,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.accentColor : Colors.white,
              border: Border.all(
                color: isCompleted ? AppColors.accentColor : AppColors.textGray,
                width: 2,
              ),
            ),
            child: isCompleted
                ? SvgPicture.asset(
                    AppIcons.check,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : null,
          ),
        ),
        onTap: isUpdatingCompletion ? null : onToggle,
        title: Text(
          wishlist.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: Colors.black,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Eliminar deseo',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _WishlistEmpty extends StatelessWidget {
  const _WishlistEmpty({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'Todavía no tienes deseos guardados.',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Cuando guardes un deseo lo verás aquí.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          OutlinedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('Crear primer deseo'),
          ),
        ],
      ),
    );
  }
}

class _WishlistError extends StatelessWidget {
  const _WishlistError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'No pudimos cargar tu wishlist.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
