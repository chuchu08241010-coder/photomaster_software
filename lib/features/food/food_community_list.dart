import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'data/food_post.dart';
import 'widgets/food_post_card.dart';

/// 某个美食社区（推荐/避雷）的帖子列表。
class FoodCommunityList extends StatefulWidget {
  const FoodCommunityList({super.key, required this.community});

  final String community;

  @override
  State<FoodCommunityList> createState() => FoodCommunityListState();
}

class FoodCommunityListState extends State<FoodCommunityList> {
  final _repo = FoodPostRepository();
  final _favRepo = FavoriteRepository();
  late Future<({List<FoodPost> posts, Set<String> favIds})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<FoodPost> posts, Set<String> favIds})> _load() async {
    final results = await Future.wait([
      _repo.fetchByCommunity(widget.community),
      _favRepo.myFavoriteIds(ItemType.foodPost),
    ]);
    return (
      posts: results[0] as List<FoodPost>,
      favIds: results[1] as Set<String>,
    );
  }

  void reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<FoodPost> posts, Set<String> favIds})>(
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
            icon: widget.community == 'recommend'
                ? Icons.thumb_up_alt_outlined
                : Icons.warning_amber_outlined,
            title: widget.community == 'recommend' ? '还没有推荐' : '还没有避雷',
            subtitle: '点右下角 + 发一条',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, i) => FoodPostCard(
              post: posts[i],
              initiallyFavorited: favIds.contains(posts[i].id),
            ),
          ),
        );
      },
    );
  }
}
