import '../../../core/supabase/supabase_client.dart';

/// 文字帖类型（6 种）。code 存库，label 展示。
const List<(String code, String label)> kTextPostTypes = [
  ('equipment', '器材分享'),
  ('tips', '拍摄技巧/教程'),
  ('question', '提问求助'),
  ('postprocess', '后期参数'),
  ('preset', '预设参数'),
  ('spot', '机位分享'),
];

String textPostTypeLabel(String code) {
  for (final t in kTextPostTypes) {
    if (t.$1 == code) return t.$2;
  }
  return code;
}

/// 文字帖数据模型，对应 public.text_posts。
class TextPost {
  const TextPost({
    required this.id,
    required this.authorId,
    required this.type,
    required this.title,
    required this.body,
    required this.location,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String type;
  final String title;
  final String body;
  final String? location;
  final DateTime createdAt;

  String get typeLabel => textPostTypeLabel(type);

  factory TextPost.fromMap(Map<String, dynamic> map) {
    return TextPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      type: (map['type'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      location: map['location'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 文字帖仓储。
class TextPostRepository {
  Future<List<TextPost>> fetchAll({String? type, int limit = 50}) async {
    var query = supabase.from('text_posts').select();
    if (type != null) query = query.eq('type', type);
    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((e) => TextPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<TextPost> create({
    required String type,
    required String title,
    required String body,
    String? location,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录，无法发帖');
    final inserted = await supabase
        .from('text_posts')
        .insert({
          'author_id': uid,
          'type': type,
          'title': title,
          'body': body,
          'location': location,
        })
        .select()
        .single();
    return TextPost.fromMap(inserted);
  }

  Future<List<TextPost>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await supabase
        .from('text_posts')
        .select()
        .or('title.ilike.%$q%,body.ilike.%$q%,location.ilike.%$q%')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => TextPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
