import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../profile/data/profile.dart';
import 'data/notification.dart';

/// 通知页：目前主要是「有人评论了你的帖子」。打开即全部标记为已读。
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = NotificationRepository();
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final list = await _repo.list();
    // 拉取后统一标记已读。
    await _repo.markAllRead();
    return list;
  }

  String _fmtTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return const SectionPlaceholder(
              icon: Icons.notifications_none,
              title: '还没有消息',
              subtitle: '有人评论你的帖子时会在这里提醒',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 64,
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            itemBuilder: (context, i) {
              final n = list[i];
              return FutureBuilder<Profile?>(
                future: n.actorId == null
                    ? Future.value(null)
                    : ProfileCache.get(n.actorId!),
                builder: (context, ps) {
                  final name = ps.data?.name ?? '有人';
                  final avatar = ps.data?.avatarUrl;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? NetworkImage(avatar)
                          : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? Icon(Icons.person,
                              color: theme.colorScheme.onPrimaryContainer)
                          : null,
                    ),
                    title: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const TextSpan(text: '  评论了你的帖子'),
                      ]),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.body != null && n.body!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('“${n.body}”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        Text(_fmtTime(n.createdAt),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
