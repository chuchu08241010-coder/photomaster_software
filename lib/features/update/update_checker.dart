import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase/supabase_config.dart';
import 'data/app_release.dart';

/// 检查是否有新版本；有则弹窗提示更新。整个流程静默失败，不打扰主流程。
class UpdateChecker {
  static bool _checkedThisSession = false;

  static Future<void> maybePrompt(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;
    if (!SupabaseConfig.isConfigured) return;
    try {
      final release = await AppReleaseRepository().fetch();
      if (release == null) return;
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      if (release.versionCode <= current) return;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('发现新版本 ${release.versionName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (release.notes != null && release.notes!.trim().isNotEmpty)
                Text(release.notes!)
              else
                const Text('有新版本可用，建议更新。'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后'),
            ),
            if (release.url != null && release.url!.isNotEmpty)
              FilledButton(
                onPressed: () async {
                  final uri = Uri.tryParse(release.url!);
                  if (uri != null) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('前往更新'),
              ),
          ],
        ),
      );
    } catch (_) {
      // 忽略
    }
  }
}
