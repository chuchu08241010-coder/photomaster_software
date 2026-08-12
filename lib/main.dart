import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅在提供了云端凭据时初始化 Supabase；否则以骨架/离线模式启动。
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    // 正式版：邮箱验证码登录（持久会话，换设备可找回）。
    // 体验版(demo)：匿名登录 + 永久邀请码，避免邮箱被刷。
    if (SupabaseConfig.isDemo) {
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        try {
          await auth.signInAnonymously();
        } catch (e) {
          debugPrint('demo 匿名登录失败: $e');
        }
      }
    }
  }

  runApp(const ProviderScope(child: PhotoMasterApp()));
}
