import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final Set<String> _selectedWishlistIds = <String>{};
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
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mi Wishlist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: wishlistsAsync.when(
                  data: (wishlists) => _WishlistList(
                    wishlists: wishlists,
                    selectedWishlists: _selectedWishlistIds,
                    pendingRemovalWishlists: _pendingRemovalWishlistIds,
                    scrollController: _wishlistScrollController,
                    onRefresh: _refreshWishlists,
                    onCreateTap: () => _handleCreateWishlist(context),
                    onToggleWishlist: _toggleWishlistSelection,
                    onDeleteWishlist: (wishlistId) =>
                        _handleDeleteWishlist(context, wishlistId),
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
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Añadir nuevo deseo... ',
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
                          vertical: 16,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleCreateWishlist(context),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => _handleCreateWishlist(context),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
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

  void _toggleWishlistSelection(String wishlistId) {
    setState(() {
      if (_selectedWishlistIds.contains(wishlistId)) {
        _selectedWishlistIds.remove(wishlistId);
      } else {
        _selectedWishlistIds.add(wishlistId);
      }
    });
  }

  Future<void> _refreshWishlists() async {
    ref.invalidate(userWishlistProvider);
    await ref.read(userWishlistProvider.future);
  }

  Future<String?> _requireUserId(
    BuildContext context,
    String failureMessage,
  ) async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) return user.id;
    if (mounted) _showSnack(context, failureMessage);
    return null;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleDeleteWishlist(
    BuildContext context,
    String wishlistId,
  ) async {
    if (_pendingRemovalWishlistIds.contains(wishlistId)) return;

    final userId = await _requireUserId(
      context,
      'Inicia sesión para poder eliminar tus deseos.',
    );
    if (userId == null) return;

    setState(() => _pendingRemovalWishlistIds.add(wishlistId));

    try {
      final repository = ref.read(wishlistRepositoryProvider);
      await repository.deleteWishlist(wishlistId: wishlistId);
      _selectedWishlistIds.remove(wishlistId);
      await _refreshWishlists();

      if (!mounted) return;
      _showSnack(context, 'Deseo eliminado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'No se pudo eliminar el deseo: $error');
    } finally {
      if (!mounted) return;
      setState(() => _pendingRemovalWishlistIds.remove(wishlistId));
    }
  }

  Future<void> _handleCreateWishlist(BuildContext context) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack(context, 'Ingresa un título para tu deseo.');
      return;
    }

    if (_isSaving) return;

    final userId = await _requireUserId(
      context,
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
      _showSnack(context, 'Deseo guardado en tu lista.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'No se pudo guardar el deseo: $error');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }
}

class _WishlistList extends StatelessWidget {
  const _WishlistList({
    required this.wishlists,
    required this.selectedWishlists,
    required this.pendingRemovalWishlists,
    required this.scrollController,
    required this.onRefresh,
    required this.onCreateTap,
    required this.onToggleWishlist,
    required this.onDeleteWishlist,
  });

  final List<Wishlist> wishlists;
  final Set<String> selectedWishlists;
  final Set<String> pendingRemovalWishlists;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateTap;
  final void Function(String wishlistId) onToggleWishlist;
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
        child: ListView.separated(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: visibleWishlists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final wishlist = visibleWishlists[index];
            final isSelected = selectedWishlists.contains(wishlist.id);
            return _WishlistCard(
              wishlist: wishlist,
              isSelected: isSelected,
              onToggle: () => onToggleWishlist(wishlist.id),
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
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
  });

  final Wishlist wishlist;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryColor : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : Colors.black87,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
        onTap: onToggle,
        title: Text(
          wishlist.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: isSelected
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isSelected ? Colors.black54 : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
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
