import 'package:flutter/material.dart';

import '../../profile/widgets/author_header.dart';
import '../../social/comments_sheet.dart';
import '../../social/favorite_repository.dart';
import '../../social/item_type.dart';
import '../data/food_post.dart';

/// 美食帖卡片：社区标签 + 店名 + 图片 + 正文 + 地址 + 收藏/评论。
class FoodPostCard extends StatefulWidget {
  const FoodPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
  });

  final FoodPost post;
  final bool initiallyFavorited;

  @override
  State<FoodPostCard> createState() => _FoodPostCardState();
}

class _FoodPostCardState extends State<FoodPostCard> {
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
        itemType: ItemType.foodPost,
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
    final badgeColor = post.isRecommend ? Colors.green : Colors.deepOrange;
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
              aspectRatio: 4 / 3,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.isRecommend ? '推荐' : '避雷',
                        style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (post.storeName.isNotEmpty)
                      Expanded(
                        child: Text(
                          post.storeName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
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
                      Expanded(
                        child: Text(post.location!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                  itemType: ItemType.foodPost,
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
