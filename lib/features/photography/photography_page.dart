import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/section_placeholder.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'create_photo_post_page.dart';
import 'data/photo_post.dart';
import 'data/photo_post_repository.dart';
import 'widgets/photo_post_card.dart';

typedef TimelineData = ({List<PhotoPost> posts, Set<String> favIds});

/// 摄影板块。
/// 两个子页：时间线（朋友圈式动态）与文字帖（独立于图片分享）。
class PhotographyPage extends StatefulWidget {
  const PhotographyPage({super.key});

  @override
  State<PhotographyPage> createState() => _PhotographyPageState();
}

class _PhotographyPageState extends State<PhotographyPage> {
  final _repo = PhotoPostRepository();
  final _favRepo = FavoriteRepository();
  late Future<TimelineData> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _timelineFuture = _load();
  }

  Future<TimelineData> _load() async {
    if (!SupabaseConfig.isConfigured) {
      return (posts: <PhotoPost>[], favIds: <String>{});
    }
    final results = await Future.wait([
      _repo.fetchTimeline(),
      _favRepo.myFavoriteIds(ItemType.photoPost),
    ]);
    return (
      posts: results[0] as List<PhotoPost>,
      favIds: results[1] as Set<String>,
    );
  }

  void _refresh() {
    setState(() => _timelineFuture = _load());
  }

  Future<void> _openCreate() async {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前为离线骨架模式，未连接云端，暂不能发帖')),
      );
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePhotoPostPage()),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('摄影'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '时间线'),
              Tab(text: '文字帖'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TimelineView(future: _timelineFuture, onRefresh: _refresh),
            const SectionPlaceholder(
              icon: Icons.article_outlined,
              title: '文字帖分享',
              subtitle: '分 N 种类型的文字分享，与图片隔离\n可收藏 · 评论',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreate,
          child: const Icon(Icons.add_a_photo),
        ),
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.future, required this.onRefresh});

  final Future<TimelineData> future;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TimelineData>(
      future: future,
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
            icon: Icons.dynamic_feed_outlined,
            title: '还没有照片',
            subtitle: '点右下角 + 发第一条摄影帖',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, i) => PhotoPostCard(
              post: posts[i],
              initiallyFavorited: favIds.contains(posts[i].id),
            ),
          ),
        );
      },
    );
  }
}

