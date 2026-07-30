/// Supabase 连接配置。
///
/// 出于安全考虑，凭据不硬编码在代码里，而是通过运行时的 --dart-define 注入：
///
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
///
/// 在 Supabase 控制台 → Project Settings → API 可找到这两个值。
/// 未配置时 app 仍可启动（骨架/离线模式），只是云端功能不可用。
class SupabaseConfig {
  SupabaseConfig._();

  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  /// 是否已提供有效的云端凭据。
  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty;
}
