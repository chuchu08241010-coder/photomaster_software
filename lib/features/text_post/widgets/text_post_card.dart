import 'package:flutter/material.dart';

import '../../profile/widgets/author_header.dart';
import '../../social/item_type.dart';
import '../../social/post_actions_bar.dart';
import '../create_text_post_page.dart';
import '../data/text_post.dart';

/// 文字帖卡片：作者 + 类型标签 + 标题 + 正文 + 地址 + 操作。
class TextPostCard extends StatelessWidget {
  const TextPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
    this.onDeleted,
  });

  final TextPost post;
  final bool initiallyFavorited;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorHeader(authorId: post.authorId, time: post.createdAt),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(post.typeLabel),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
            if (post.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
            if (post.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(post.body),
            ],
            if (post.location != null && post.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(post.location!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ],
            PostActionsBar(
              itemType: ItemType.textPost,
              itemId: post.id,
              authorId: post.authorId,
              initiallyFavorited: initiallyFavorited,
              onDelete: () => TextPostRepository().delete(post.id),
              onDeleted: onDeleted,
              onEdit: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CreateTextPostPage(editing: post),
                  ),
                );
                if (ok == true) onDeleted?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
