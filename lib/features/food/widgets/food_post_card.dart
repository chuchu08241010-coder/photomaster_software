import 'package:flutter/material.dart';

import '../../profile/widgets/author_header.dart';
import '../../social/item_type.dart';
import '../../social/post_actions_bar.dart';
import '../data/food_post.dart';

/// 美食帖卡片：作者 + 社区标签 + 店名 + 图片 + 正文 + 地址 + 操作。
class FoodPostCard extends StatelessWidget {
  const FoodPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
    this.onDeleted,
  });

  final FoodPost post;
  final bool initiallyFavorited;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          PostActionsBar(
            itemType: ItemType.foodPost,
            itemId: post.id,
            authorId: post.authorId,
            initiallyFavorited: initiallyFavorited,
            onDelete: () => FoodPostRepository().delete(post.id),
            onDeleted: onDeleted,
          ),
        ],
      ),
    );
  }
}
