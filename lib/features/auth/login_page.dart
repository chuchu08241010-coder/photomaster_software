import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/supabase_config.dart';
import '../drift_bottle/welcome_drift_page.dart';
import '../profile/data/profile.dart';

/// 登录页（邮箱验证码）。
/// 身份绑定到邮箱：换手机/重装用同邮箱登录即同一账号，帖子不丢。
/// 流程：输入邮箱 → 收验证码并验证 →（新用户）设昵称 → 进入。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _Phase { loading, email, code, profile }

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _inviteController = TextEditingController();
  final _nameController = TextEditingController();
  final _profileRepo = ProfileRepository();

  _Phase _phase = _Phase.loading;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _inviteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _phase = _Phase.email);
      return;
    }
    // 体验版：确保拿到匿名会话（不发邮件）。
    if (SupabaseConfig.isDemo && supabase.auth.currentSession == null) {
      try {
        await supabase.auth.signInAnonymously();
      } catch (_) {}
    }
    // 已有会话：老用户直接进；无资料则去补（正式版=昵称；体验版=邀请码+昵称）。
    if (supabase.auth.currentSession != null) {
      try {
        final profile = await _profileRepo.getMine();
        final hasName = profile?.displayName?.trim().isNotEmpty ?? false;
        if (hasName) {
          await _goHome();
          return;
        }
        if (mounted) setState(() => _phase = _Phase.profile);
        return;
      } catch (_) {
        // 拉取失败：体验版仍去填邀请码；正式版按老用户放行。
        if (SupabaseConfig.isDemo) {
          if (mounted) setState(() => _phase = _Phase.profile);
        } else {
          await _goHome();
        }
        return;
      }
    }
    if (mounted) {
      setState(() =>
          _phase = SupabaseConfig.isDemo ? _Phase.profile : _Phase.email);
    }
  }

  /// 进入主界面：每日首次先展示漂流瓶开场，否则直达时间线。
  Future<void> _goHome() async {
    final showWelcome = await WelcomeDriftPage.shouldShow();
    if (!mounted) return;
    context.go(showWelcome ? '/welcome' : '/photography');
  }

  bool _validEmail(String s) =>
      RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(s);

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!_validEmail(email)) {
      _snack('请输入正确的邮箱');
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.auth.signInWithOtp(email: email);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.code;
        _submitting = false;
      });
      _snack('验证码已发送到 $email，请查收（含垃圾箱）');
    } catch (e) {
      _snack('发送失败：$e');
      setState(() => _submitting = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _snack('请输入验证码');
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      // 验证成功：判断是老用户还是新用户。
      final profile = await _profileRepo.getMine();
      final hasName = profile?.displayName?.trim().isNotEmpty ?? false;
      if (!mounted) return;
      if (hasName) {
        await _goHome();
      } else {
        setState(() {
          _phase = _Phase.profile;
          _submitting = false;
        });
      }
    } catch (e) {
      _snack('验证失败：$e');
      setState(() => _submitting = false);
    }
  }

  Future<void> _finishProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('请设置一个昵称');
      return;
    }
    setState(() => _submitting = true);
    try {
      // 体验版：先用永久邀请码兑换（匿名身份即可），不走邮箱。
      if (SupabaseConfig.isDemo) {
        final code = _inviteController.text.trim();
        if (code.isEmpty) {
          _snack('请输入体验邀请码');
          setState(() => _submitting = false);
          return;
        }
        if (supabase.auth.currentSession == null) {
          await supabase.auth.signInAnonymously();
        }
        final ok = await supabase
            .rpc('redeem_invite', params: {'p_code': code}) as bool?;
        if (ok != true) {
          _snack('邀请码无效');
          setState(() => _submitting = false);
          return;
        }
      }
      await _profileRepo.upsert(displayName: name);
      if (!mounted) return;
      await _goHome();
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
    if (_phase == _Phase.loading) {
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
                Icon(Icons.camera, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('PhotoMaster',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('小圈子 · 影像分享与分析',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 36),
                if (!SupabaseConfig.isConfigured)
                  _offline(theme)
                else
                  ..._phaseBody(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _phaseBody(ThemeData theme) {
    switch (_phase) {
      case _Phase.email:
        return [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '邮箱',
              hintText: '用邮箱登录，换手机也能找回身份',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _sendCode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _submitting ? _spinner() : const Text('发送验证码'),
            ),
          ),
        ];
      case _Phase.code:
        return [
          Text('验证码已发送到\n${_emailController.text.trim()}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '6 位验证码',
              hintText: '输入邮件里的验证码',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _verifyCode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _submitting ? _spinner() : const Text('验证并进入'),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : _sendCode,
            child: const Text('没收到？重新发送'),
          ),
          TextButton(
            onPressed: _submitting
                ? null
                : () => setState(() => _phase = _Phase.email),
            child: const Text('换个邮箱'),
          ),
        ];
      case _Phase.profile:
        return [
          Text(
              SupabaseConfig.isDemo
                  ? '体验版 · 输入邀请码 + 昵称即可进入'
                  : '首次加入，给自己起个昵称',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (SupabaseConfig.isDemo) ...[
            TextField(
              controller: _inviteController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: '体验邀请码',
                hintText: '如 PMDEMO',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: '昵称',
              hintText: '给自己起个名字',
            ),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: _submitting ? null : _finishProfile,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _submitting ? _spinner() : const Text('进入'),
            ),
          ),
        ];
      case _Phase.loading:
        return const [];
    }
  }

  Widget _offline(ThemeData theme) => Column(
        children: [
          Text('当前为骨架/离线模式：尚未配置 Supabase 云端。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/photography'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('以离线模式进入'),
            ),
          ),
        ],
      );

  Widget _spinner() => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
