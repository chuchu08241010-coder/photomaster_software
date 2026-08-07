import 'package:flutter/material.dart';

import '../../../core/widgets/image_viewer_page.dart';
import '../../../core/widgets/network_photo.dart';
import '../../profile/widgets/author_header.dart';
import '../../social/item_type.dart';
import '../../social/post_actions_bar.dart';
import '../create_photo_post_page.dart';
import '../data/photo_post.dart';
import '../data/photo_post_repository.dart';

/// 时间线/主页通用的摄影帖卡片：作者 + 图片 + 文案 + 标签 + 地址 + EXIF + 操作。
class PhotoPostCard extends StatelessWidget {
  const PhotoPostCard({
    super.key,
    required this.post,
    this.initiallyFavorited = false,
    this.onDeleted,
  });

  final PhotoPost post;
  final bool initiallyFavorited;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AuthorHeader(authorId: post.authorId, time: post.createdAt),
          ),
          if (post.imageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: PageView(
                children: [
                  for (var i = 0; i < post.imageUrls.length; i++)
                    GestureDetector(
                      onTap: () => ImageViewerPage.open(
                          context, post.imageUrls, i),
                      child: NetworkPhoto(post.imageUrls[i]),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
          PostActionsBar(
            itemType: ItemType.photoPost,
            itemId: post.id,
            authorId: post.authorId,
            initiallyFavorited: initiallyFavorited,
            onDelete: () => PhotoPostRepository().delete(post.id),
            onDeleted: onDeleted,
            onEdit: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CreatePhotoPostPage(editing: post),
                ),
              );
              if (ok == true) onDeleted?.call();
            },
          ),
        ],
      ),
    );
  }
}
