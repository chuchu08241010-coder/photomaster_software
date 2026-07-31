import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'data/photo_post.dart';
import 'data/photo_post_repository.dart';
import 'widgets/photo_post_card.dart';

/// 摄影关键词搜索：匹配文案 / #标签 / 地址。
class SearchPhotoPage extends StatefulWidget {
  const SearchPhotoPage({super.key});

  @override
  State<SearchPhotoPage> createState() => _SearchPhotoPageState();
}

class _SearchPhotoPageState extends State<SearchPhotoPage> {
  final _repo = PhotoPostRepository();
  final _favRepo = FavoriteRepository();
  final _controller = TextEditingController();

  Future<List<PhotoPost>>? _future;
  Set<String> _favIds = {};
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _favRepo.myFavoriteIds(ItemType.photoPost).then((ids) {
      if (mounted) setState(() => _favIds = ids);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    setState(() {
      _searched = true;
      _future = _repo.search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索文案 / #标签 / 地址',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _future == null
          ? const SectionPlaceholder(
              icon: Icons.search,
              title: '输入关键词搜索',
              subtitle: '按文案、#标签或地址查找过往照片',
            )
          : FutureBuilder<List<PhotoPost>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return SectionPlaceholder(
                    icon: Icons.error_outline,
                    title: '搜索失败',
                    subtitle: '${snapshot.error}',
                  );
                }
                final posts = snapshot.data ?? const [];
                if (posts.isEmpty && _searched) {
                  return const SectionPlaceholder(
                    icon: Icons.sentiment_dissatisfied,
                    title: '没有找到相关照片',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => PhotoPostCard(
                    post: posts[i],
                    initiallyFavorited: _favIds.contains(posts[i].id),
                  ),
                );
              },
            ),
    );
  }
}
