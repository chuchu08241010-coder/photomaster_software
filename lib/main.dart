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

    // 邀请制真正落地前，先用匿名登录拿到持久用户身份，才能发帖/上传。
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        // 匿名登录未开启或网络问题时不阻塞启动，进离线体验。
        debugPrint('匿名登录失败: $e');
      }
    }
  }

  runApp(const ProviderScope(child: PhotoMasterApp()));
}
