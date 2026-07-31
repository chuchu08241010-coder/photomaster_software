import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// 全局 Supabase 客户端访问入口。
/// 仅在已配置凭据时可用；离线骨架模式下调用会抛异常，调用方应先判断 isConfigured。
SupabaseClient get supabase => Supabase.instance.client;

/// 当前登录用户 id（未登录返回 null）。
String? get currentUserId =>
    SupabaseConfig.isConfigured ? supabase.auth.currentUser?.id : null;
