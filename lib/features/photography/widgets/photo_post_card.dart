import 'package:flutter/material.dart';

import '../../profile/widgets/author_header.dart';
import '../../social/comments_sheet.dart';
import '../../social/favorite_repository.dart';
import '../../social/item_type.dart';
import '../data/photo_post.dart';

/// 时间线/主页通用的摄影帖卡片：图片轮播 + 文案 + 标签 + 地址 + 收藏/评论。
class PhotoPostCard extends StatefulWidget {
  const PhotoPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
  });

  final PhotoPost post;
  final bool initiallyFavorited;

  @override
  State<PhotoPostCard> createState() => _PhotoPostCardState();
}

class _PhotoPostCardState extends State<PhotoPostCard> {
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
        itemType: ItemType.photoPost,
        itemId: widget.post.id,
        value: next,
      );
    } catch (e) {
      setState(() => _favorited = !next); // 回滚
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: AuthorHeader(authorId: post.authorId, time: post.createdAt),
          ),
          if (post.imageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: PageView(
                children: [
                  for (final url in post.imageUrls)
                    Image.network(url, fit: BoxFit.cover),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.caption.isNotEmpty) Text(post.caption),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      for (final tag in post.tags)
                        Chip(
                          label: Text('#$tag'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
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
                if (post.exif != null && !post.exif!.isEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.camera_outlined,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(post.exif!.summary,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 操作区：收藏 + 评论（摄影不点赞）
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
                  itemType: ItemType.photoPost,
                  itemId: post.id,
                ),
                icon: const Icon(Icons.mode_comment_outlined),
                tooltip: '评论',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
