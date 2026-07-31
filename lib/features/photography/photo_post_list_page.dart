import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'data/photo_post.dart';
import 'widgets/photo_post_card.dart';

/// 通用的摄影帖列表页（我的照片 / 我的收藏都复用）。
class PhotoPostListPage extends StatefulWidget {
  const PhotoPostListPage({
    super.key,
    required this.title,
    required this.loader,
    this.emptyHint = '这里还没有内容',
  });

  final String title;
  final Future<List<PhotoPost>> Function() loader;
  final String emptyHint;

  @override
  State<PhotoPostListPage> createState() => _PhotoPostListPageState();
}

class _PhotoPostListPageState extends State<PhotoPostListPage> {
  final _favRepo = FavoriteRepository();
  late Future<({List<PhotoPost> posts, Set<String> favIds})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<PhotoPost> posts, Set<String> favIds})> _load() async {
    final results = await Future.wait([
      widget.loader(),
      _favRepo.myFavoriteIds(ItemType.photoPost),
    ]);
    return (
      posts: results[0] as List<PhotoPost>,
      favIds: results[1] as Set<String>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<({List<PhotoPost> posts, Set<String> favIds})>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPlaceholder(
              icon: Icons.error_outline,
              title: '加载失败',
              subtitle: '${snapshot.error}',
            );
          }
          final posts = snapshot.data?.posts ?? const [];
          final favIds = snapshot.data?.favIds ?? const <String>{};
          if (posts.isEmpty) {
            return SectionPlaceholder(
              icon: Icons.photo_library_outlined,
              title: widget.emptyHint,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, i) => PhotoPostCard(
                post: posts[i],
                initiallyFavorited: favIds.contains(posts[i].id),
                onDeleted: () => setState(() => _future = _load()),
              ),
            ),
          );
        },
      ),
    );
  }
}
