import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../settings/settings_page.dart';

/// 「我的」页：个人主页 + 设置入口。骨架阶段仅展示占位与退出。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          const ListTile(
            leading: Icon(Icons.photo_library_outlined),
            title: Text('我的照片'),
          ),
          const ListTile(
            leading: Icon(Icons.bookmark_border),
            title: Text('我的收藏'),
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
