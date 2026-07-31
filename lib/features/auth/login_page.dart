import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_config.dart';
import '../profile/data/profile.dart';
import 'data/invite_service.dart';

/// 登录页（邀请制，一码一用）。
/// 已进过圈子的用户（本机）会自动跳过；新用户需输入有效邀请码 + 昵称。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _joinedKey = 'joined_circle';

  final _inviteController = TextEditingController();
  final _nameController = TextEditingController();
  final _inviteService = InviteService();
  final _profileRepo = ProfileRepository();

  bool _submitting = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _autoSkipIfJoined();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _autoSkipIfJoined() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _checking = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_joinedKey) == true && mounted) {
      context.go('/photography');
      return;
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _enter() async {
    // 离线骨架模式：直接进入。
    if (!SupabaseConfig.isConfigured) {
      context.go('/photography');
      return;
    }
    final code = _inviteController.text.trim();
    final name = _nameController.text.trim();
    if (code.isEmpty) {
      _snack('请输入邀请码');
      return;
    }
    if (name.isEmpty) {
      _snack('请设置一个昵称');
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await _inviteService.redeem(code);
      if (!ok) {
        _snack('邀请码无效或已被使用');
        setState(() => _submitting = false);
        return;
      }
      await _profileRepo.upsert(displayName: name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_joinedKey, true);
      if (!mounted) return;
      context.go('/photography');
    } catch (e) {
      _snack('进入失败：$e');
      setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    hintText: '给自己起个名字',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitting ? null : _enter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('进入圈子'),
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
