import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/section_placeholder.dart';
import 'create_photo_post_page.dart';
import 'data/photo_post.dart';
import 'data/photo_post_repository.dart';

/// 摄影板块。
/// 两个子页：时间线（朋友圈式动态）与文字帖（独立于图片分享）。
class PhotographyPage extends StatefulWidget {
  const PhotographyPage({super.key});

  @override
  State<PhotographyPage> createState() => _PhotographyPageState();
}

class _PhotographyPageState extends State<PhotographyPage> {
  final _repo = PhotoPostRepository();
  late Future<List<PhotoPost>> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _timelineFuture = _load();
  }

  Future<List<PhotoPost>> _load() {
    if (!SupabaseConfig.isConfigured) return Future.value(const []);
    return _repo.fetchTimeline();
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

  final Future<List<PhotoPost>> future;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PhotoPost>>(
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
        final posts = snapshot.data ?? const [];
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
            itemBuilder: (context, i) => _PhotoPostCard(post: posts[i]),
          ),
        );
      },
    );
  }
}

class _PhotoPostCard extends StatelessWidget {
  const _PhotoPostCard({required this.post});

  final PhotoPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            padding: const EdgeInsets.all(12),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

