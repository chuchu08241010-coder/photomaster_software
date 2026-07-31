import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'data/text_post.dart';
import 'widgets/text_post_card.dart';

/// 文字帖列表（供摄影板块「文字帖」子页使用），带类型筛选。
class TextPostList extends StatefulWidget {
  const TextPostList({super.key});

  @override
  State<TextPostList> createState() => TextPostListState();
}

class TextPostListState extends State<TextPostList> {
  final _repo = TextPostRepository();
  final _favRepo = FavoriteRepository();

  String? _typeFilter; // null = 全部
  late Future<({List<TextPost> posts, Set<String> favIds})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<TextPost> posts, Set<String> favIds})> _load() async {
    final results = await Future.wait([
      _repo.fetchAll(type: _typeFilter),
      _favRepo.myFavoriteIds(ItemType.textPost),
    ]);
    return (
      posts: results[0] as List<TextPost>,
      favIds: results[1] as Set<String>,
    );
  }

  /// 供外部（发帖成功后）刷新。
  void reload() => setState(() => _future = _load());

  void _setFilter(String? type) {
    setState(() {
      _typeFilter = type;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: const Text('全部'),
                  selected: _typeFilter == null,
                  onSelected: (_) => _setFilter(null),
                ),
              ),
              for (final t in kTextPostTypes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(t.$2),
                    selected: _typeFilter == t.$1,
                    onSelected: (_) => _setFilter(t.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<({List<TextPost> posts, Set<String> favIds})>(
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
                return const SectionPlaceholder(
                  icon: Icons.article_outlined,
                  title: '还没有文字帖',
                  subtitle: '点右下角 + 发一条',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => TextPostCard(
                    post: posts[i],
                    initiallyFavorited: favIds.contains(posts[i].id),
                    onDeleted: reload,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
