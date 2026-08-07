import '../../../core/supabase/supabase_client.dart';

/// 最新版本信息，对应 public.app_release（单行 id=1）。
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.notes,
    required this.url,
  });

  final int versionCode;
  final String versionName;
  final String? notes;
  final String? url;

  factory AppRelease.fromMap(Map<String, dynamic> m) => AppRelease(
        versionCode: (m['version_code'] as num?)?.toInt() ?? 0,
        versionName: (m['version_name'] as String?) ?? '',
        notes: m['notes'] as String?,
        url: m['url'] as String?,
      );
}

class AppReleaseRepository {
  /// 拉取最新版本信息。任何异常（如表未建）返回 null。
  Future<AppRelease?> fetch() async {
    try {
      final rows =
          await supabase.from('app_release').select().eq('id', 1).limit(1);
      final list = rows as List;
      if (list.isEmpty) return null;
      return AppRelease.fromMap(list.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
