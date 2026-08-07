import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/section_placeholder.dart';
import '../announcement/announcement_banner.dart';
import '../location/data/ip_location_service.dart';
import '../notifications/data/notification.dart';
import '../notifications/notifications_page.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import '../text_post/create_text_post_page.dart';
import '../text_post/text_post_list.dart';
import '../update/update_checker.dart';
import 'create_photo_post_page.dart';
import 'data/photo_post.dart';
import 'data/photo_post_repository.dart';
import 'search_photo_page.dart';
import 'widgets/photo_post_card.dart';

typedef TimelineData = ({List<PhotoPost> posts, Set<String> favIds});

/// 摄影板块。
/// 两个子页：时间线（朋友圈式动态）与文字帖（独立于图片分享）。
class PhotographyPage extends StatefulWidget {
  const PhotographyPage({super.key});

  @override
  State<PhotographyPage> createState() => _PhotographyPageState();
}

class _PhotographyPageState extends State<PhotographyPage>
    with SingleTickerProviderStateMixin {
  final _repo = PhotoPostRepository();
  final _favRepo = FavoriteRepository();
  final _notifRepo = NotificationRepository();
  final _textListKey = GlobalKey<TextPostListState>();
  late final TabController _tabController;
  late Future<TimelineData> _timelineFuture;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _timelineFuture = _load();
    _loadUnread();
    // 首帧后：检查新版本、刷新 IP 属地（每天一次）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateChecker.maybePrompt(context);
      IpLocationService.refreshDaily();
    });
  }

  Future<void> _loadUnread() async {
    if (!SupabaseConfig.isConfigured) return;
    final n = await _notifRepo.unreadCount();
    if (mounted) setState(() => _unread = n);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    _loadUnread();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  bool _guardOnline() {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前为离线骨架模式，未连接云端，暂不能发帖')),
      );
      return false;
    }
    return true;
  }

  Future<void> _openCreate() async {
    if (!_guardOnline()) return;
    if (_tabController.index == 1) {
      // 文字帖
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CreateTextPostPage()),
      );
      if (created == true) _textListKey.currentState?.reload();
    } else {
      // 时间线（图片）
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CreatePhotoPostPage()),
      );
      if (created == true) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isText = _tabController.index == 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('摄影'),
        actions: [
          IconButton(
            icon: _unread > 0
                ? Badge(
                    label: Text('$_unread'),
                    child: const Icon(Icons.notifications_none),
                  )
                : const Icon(Icons.notifications_none),
            tooltip: '消息',
            onPressed: () {
              if (!_guardOnline()) return;
              _openNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              if (!_guardOnline()) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchPhotoPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '时间线'),
            Tab(text: '文字帖'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TimelineView(future: _timelineFuture, onRefresh: _refresh),
          TextPostList(key: _textListKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: isText ? '发文字帖' : '发摄影帖',
        child: Icon(isText ? Icons.edit : Icons.add_a_photo),
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
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: posts.isEmpty ? 2 : posts.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return const AnnouncementBanner();
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: SectionPlaceholder(
                    icon: Icons.dynamic_feed_outlined,
                    title: '还没有照片',
                    subtitle: '点右下角 + 发第一条摄影帖',
                  ),
                );
              }
              final post = posts[i - 1];
              return PhotoPostCard(
                post: post,
                initiallyFavorited: favIds.contains(post.id),
                onDeleted: onRefresh,
              );
            },
          ),
        );
      },
    );
  }
}

