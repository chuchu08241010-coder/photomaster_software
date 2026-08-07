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
    // 身份改为邮箱验证码登录（持久会话，换设备可找回）。
    // 会话由 supabase_flutter 本地持久化，登录页据此判断是否已登录。
  }

  runApp(const ProviderScope(child: PhotoMasterApp()));
}
