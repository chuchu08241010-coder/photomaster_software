import 'package:flutter/material.dart';

import '../../social/comments_sheet.dart';
import '../../social/favorite_repository.dart';
import '../../social/item_type.dart';
import '../data/text_post.dart';

/// 文字帖卡片：类型标签 + 标题 + 正文 + 地址 + 收藏/评论。
class TextPostCard extends StatefulWidget {
  const TextPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
  });

  final TextPost post;
  final bool initiallyFavorited;

  @override
  State<TextPostCard> createState() => _TextPostCardState();
}

class _TextPostCardState extends State<TextPostCard> {
  final _favRepo = FavoriteRepository();
  late bool _favorited = widget.initiallyFavorited;
  bool _busy = false;

  Future<void> _toggleFavorite() async {
    if (_busy) return;
    final next = !_favorited;
    setState(() {
      _favorited = next;
      _busy = true;
    });
    try {
      await _favRepo.setFavorite(
        itemType: ItemType.textPost,
        itemId: widget.post.id,
        value: next,
      );
    } catch (e) {
      setState(() => _favorited = !next);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _favorited ? Icons.bookmark : Icons.bookmark_border,
                    color: _favorited ? theme.colorScheme.primary : null,
                  ),
                  tooltip: '收藏',
                ),
                IconButton(
                  onPressed: () => showCommentsSheet(
                    context,
                    itemType: ItemType.textPost,
                    itemId: post.id,
                  ),
                  icon: const Icon(Icons.mode_comment_outlined),
                  tooltip: '评论',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
