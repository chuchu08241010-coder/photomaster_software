import 'package:flutter/material.dart';

import '../data/profile.dart';

/// 帖子头部：作者头像 + 昵称（+ 可选时间、右侧操作）。
class AuthorHeader extends StatelessWidget {
  const AuthorHeader({
    super.key,
    required this.authorId,
    this.time,
    this.trailing,
  });

  final String authorId;
  final DateTime? time;
  final Widget? trailing;

  String _fmtTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Profile?>(
      future: ProfileCache.get(authorId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name ?? '匿名用户';
        final avatarUrl = profile?.avatarUrl;
        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(Icons.person,
                      size: 20, color: theme.colorScheme.onPrimaryContainer)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (time != null)
                    Text(_fmtTime(time!),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        );
      },
    );
  }
}
