import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../photography/data/photo_post_repository.dart';
import '../photography/photo_post_list_page.dart';
import '../settings/settings_page.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';

/// 「我的」页：个人主页 + 设置入口。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _openMyPhotos(BuildContext context) {
    final repo = PhotoPostRepository();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoPostListPage(
        title: '我的照片',
        emptyHint: '你还没发过摄影帖',
        loader: () async {
          final uid = currentUserId;
          if (uid == null) return const [];
          return repo.fetchByAuthor(uid);
        },
      ),
    ));
  }

  void _openMyFavorites(BuildContext context) {
    final repo = PhotoPostRepository();
    final favRepo = FavoriteRepository();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoPostListPage(
        title: '我的收藏',
        emptyHint: '还没有收藏的照片',
        loader: () async {
          final ids = await favRepo.myFavoriteIds(ItemType.photoPost);
          return repo.fetchByIds(ids.toList());
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person,
                size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('我的主页', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('我的照片'),
            onTap: () => _openMyPhotos(context),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('我的收藏'),
            onTap: () => _openMyFavorites(context),
          ),
          const ListTile(
            leading: Icon(Icons.group_add_outlined),
            title: Text('邀请好友'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('配色方案'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('退出登录',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
