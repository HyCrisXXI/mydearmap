import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/data/models/comment.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MemoryCommentCard extends StatelessWidget {
  const MemoryCommentCard({super.key, required this.comment, this.onDelete});

  final Comment comment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = comment.subtitle?.trim();
    final hasSubtitle = subtitle?.isNotEmpty == true;
    final formattedDate = _formatCommentDate(comment.createdAt);
    final canDelete = onDelete != null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            offset: const Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _CommentAvatar(
                    name: comment.user.name,
                    avatarUrl: comment.user.profileUrl,
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.messageCircle,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            comment.user.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (canDelete)
                          _CommentActionsButton(onDelete: onDelete),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          AppIcons.calendar,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            const Color.fromARGB(255, 94, 103, 242),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            comment.content.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (hasSubtitle) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            Divider(
              color: theme.colorScheme.outlineVariant.withAlpha(0x66),
              thickness: 0.5,
              height: 12,
            ),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: (theme.textTheme.bodySmall?.fontSize ?? 14) + 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(name);
    final resolvedUrl = _resolveAvatarUrl(avatarUrl);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        color: Colors.grey.shade200,
        image: resolvedUrl != null
            ? DecorationImage(
                image: NetworkImage(resolvedUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: resolvedUrl == null
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

String _formatCommentDate(DateTime date) {
  try {
    return DateFormat('dd/MM/yyyy', 'es_ES').format(date);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

String _initialsOf(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = _firstLetter(parts[0]);
  final second = parts.length > 1 ? _firstLetter(parts[1]) : '';
  final initials = (first + second).trim();
  return initials.isNotEmpty ? initials : '?';
}

String _firstLetter(String value) {
  if (value.isEmpty) return '';
  final buffer = value.runes.take(1).toList();
  return String.fromCharCodes(buffer).toUpperCase();
}

class _CommentActionsButton extends StatelessWidget {
  const _CommentActionsButton({this.onDelete});

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (onDelete == null) return const SizedBox.shrink();
    return PopupMenuButton<_CommentAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) {
        if (action == _CommentAction.delete) {
          onDelete!.call();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<_CommentAction>(
          value: _CommentAction.delete,
          child: Text('Eliminar'),
        ),
      ],
    );
  }
}

enum _CommentAction { delete }

String? _resolveAvatarUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  return 'https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/avatars/$raw';
}
