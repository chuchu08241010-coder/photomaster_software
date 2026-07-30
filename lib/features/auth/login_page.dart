import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_config.dart';

/// 登录页（邀请制）。
///
/// 骨架阶段：仅收集邀请码并进入主界面。
/// 后续接入 Supabase 后，这里会校验邀请码、创建/登录账号并加入圈子。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  void _enter() {
    // TODO: 接入 Supabase 后在此校验邀请码并完成登录。
    context.go('/photography');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.camera, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'PhotoMaster',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '小圈子 · 摄影与美食分享',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _inviteController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: '邀请码',
                    hintText: '输入好友分享给你的邀请码',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enter,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('进入圈子'),
                  ),
                ),
                if (!SupabaseConfig.isConfigured) ...[
                  const SizedBox(height: 24),
                  Text(
                    '当前为骨架/离线模式：尚未配置 Supabase 云端。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
