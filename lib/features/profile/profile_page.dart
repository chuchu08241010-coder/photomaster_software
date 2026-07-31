import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import '../drift_bottle/drift_bottle_page.dart';
import '../photography/data/photo_post_repository.dart';
import '../photography/photo_post_list_page.dart';
import '../settings/settings_page.dart';
import '../social/favorite_repository.dart';
import '../social/item_type.dart';
import 'data/profile.dart';
import 'edit_profile_page.dart';

/// 「我的」页：个人主页 + 设置入口。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileRepo = ProfileRepository();
  late Future<Profile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepo.getMine();
  }

  void _reloadProfile() {
    setState(() => _profileFuture = _profileRepo.getMine());
  }

  void _openMyPhotos() {
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

  void _openMyFavorites() {
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

  Future<void> _editProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    if (changed == true) _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          FutureBuilder<Profile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final avatarUrl = profile?.avatarUrl;
              return Column(
                children: [
                  GestureDetector(
                    onTap: _editProfile,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(Icons.person,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile?.name ?? '未设置昵称',
                      style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('编辑资料'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('我的照片'),
            onTap: _openMyPhotos,
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('我的收藏'),
            onTap: _openMyFavorites,
          ),
          const ListTile(
            leading: Icon(Icons.group_add_outlined),
            title: Text('邀请好友'),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('漂流瓶'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DriftBottlePage()),
            ),
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
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('joined_circle');
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
