import '../../../core/supabase/supabase_client.dart';

/// 通知模型，对应 public.notifications。
class AppNotification {
  const AppNotification({
    required this.id,
    required this.actorId,
    required this.type,
    required this.itemType,
    required this.itemId,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String type;
  final String? itemType;
  final String? itemId;
  final String? body;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        actorId: m['actor_id'] as String?,
        type: (m['type'] as String?) ?? '',
        itemType: m['item_type'] as String?,
        itemId: m['item_id'] as String?,
        body: m['body'] as String?,
        read: (m['read'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class NotificationRepository {
  Future<List<AppNotification>> list({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return const [];
    final rows = await supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 未读数量。任何异常（如表未建）都返回 0，避免影响主流程。
  Future<int> unreadCount() async {
    try {
      final uid = currentUserId;
      if (uid == null) return 0;
      final rows =
          await supabase.from('notifications').select('id').eq('read', false);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllRead() async {
    final uid = currentUserId;
    if (uid == null) return;
    await supabase
        .from('notifications')
        .update({'read': true})
        .eq('recipient_id', uid)
        .eq('read', false);
  }
}
