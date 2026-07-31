import '../../core/supabase/supabase_client.dart';

/// 评论数据模型，对应 public.comments。
class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      body: (map['body'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 评论仓储（通用）。
class CommentRepository {
  Future<List<Comment>> list(String itemType, String itemId) async {
    final rows = await supabase
        .from('comments')
        .select()
        .eq('item_type', itemType)
        .eq('item_id', itemId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => Comment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> add(String itemType, String itemId, String body) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    final inserted = await supabase
        .from('comments')
        .insert({
          'item_type': itemType,
          'item_id': itemId,
          'author_id': uid,
          'body': body,
        })
        .select()
        .single();
    return Comment.fromMap(inserted);
  }

  Future<int> count(String itemType, String itemId) async {
    final rows = await supabase
        .from('comments')
        .select('id')
        .eq('item_type', itemType)
        .eq('item_id', itemId);
    return (rows as List).length;
  }
}
