import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../core/supabase/supabase_client.dart';
import '../drift_bottle/drift_bottle_page.dart';
import '../help/manual_page.dart';
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
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 28),
          FutureBuilder<Profile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final avatarUrl = profile?.avatarUrl;
              return Column(
                children: [
                  GestureDetector(
                    onTap: _editProfile,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Icon(Icons.person_outline,
                                size: 40,
                                color: theme.colorScheme.onPrimaryContainer)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.name ?? '未设置昵称',
                    style: serifDisplay(size: 24),
                  ),
                  if (profile?.ipLocation?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'IP属地：${profile!.ipLocation}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('编辑资料'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _MenuGroup(children: [
            _MenuTile(
              icon: Icons.photo_library_outlined,
              title: '我的照片',
              onTap: _openMyPhotos,
            ),
            _MenuTile(
              icon: Icons.bookmark_border,
              title: '我的收藏',
              onTap: _openMyFavorites,
            ),
            _MenuTile(
              icon: Icons.water_drop_outlined,
              title: '漂流瓶',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriftBottlePage()),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _MenuGroup(children: [
            _MenuTile(
              icon: Icons.group_add_outlined,
              title: '邀请好友',
              onTap: () {},
            ),
            _MenuTile(
              icon: Icons.palette_outlined,
              title: '配色方案',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            _MenuTile(
              icon: Icons.menu_book_outlined,
              title: '使用说明',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualPage()),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _MenuGroup(children: [
            _MenuTile(
              icon: Icons.logout,
              title: '退出登录',
              danger: true,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('joined_circle');
                if (context.mounted) context.go('/login');
              },
            ),
          ]),
        ],
      ),
    );
  }
}

/// 圆角分组容器。
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 52,
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.4)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 22, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      trailing: danger
          ? null
          : Icon(Icons.chevron_right,
              size: 20, color: theme.colorScheme.outline),
      onTap: onTap,
    );
  }
}
