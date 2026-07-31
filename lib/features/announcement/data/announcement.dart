import '../../../core/supabase/supabase_client.dart';

/// 快闪活动，对应 public.announcements。
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? linkUrl;

  factory Announcement.fromMap(Map<String, dynamic> map) => Announcement(
        id: map['id'] as String,
        title: (map['title'] as String?) ?? '',
        subtitle: (map['subtitle'] as String?) ?? '',
        imageUrl: map['image_url'] as String?,
        linkUrl: map['link_url'] as String?,
      );
}

class AnnouncementRepository {
  /// 拉取生效中的快闪活动（最新在前）。缺表/异常时返回空。
  Future<List<Announcement>> fetchActive({int limit = 5}) async {
    try {
      final rows = await supabase
          .from('announcements')
          .select()
          .eq('active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((e) => Announcement.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
