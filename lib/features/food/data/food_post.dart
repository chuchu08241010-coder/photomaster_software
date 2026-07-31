import 'dart:io';

import '../../../core/supabase/supabase_client.dart';

/// 美食社区（两种）。
const List<(String code, String label)> kFoodCommunities = [
  ('recommend', '推荐'),
  ('avoid', '避雷'),
];

String foodCommunityLabel(String code) {
  for (final c in kFoodCommunities) {
    if (c.$1 == code) return c.$2;
  }
  return code;
}

/// 美食帖数据模型，对应 public.food_posts。
class FoodPost {
  const FoodPost({
    required this.id,
    required this.authorId,
    required this.community,
    required this.storeName,
    required this.body,
    required this.location,
    required this.imageUrls,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String community;
  final String storeName;
  final String body;
  final String? location;
  final List<String> imageUrls;
  final DateTime createdAt;

  bool get isRecommend => community == 'recommend';

  factory FoodPost.fromMap(Map<String, dynamic> map) {
    return FoodPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      community: (map['community'] as String?) ?? 'recommend',
      storeName: (map['store_name'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      location: map['location'] as String?,
      imageUrls: ((map['image_urls'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 美食帖仓储（图片复用 post-images 桶）。
class FoodPostRepository {
  static const String _bucket = 'post-images';

  Future<List<FoodPost>> fetchByCommunity(String community,
      {int limit = 50}) async {
    final rows = await supabase
        .from('food_posts')
        .select()
        .eq('community', community)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => FoodPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<FoodPost> create({
    required String community,
    required String storeName,
    required String body,
    String? location,
    List<File> images = const [],
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录，无法发帖');

    final imageUrls = <String>[];
    for (final image in images) {
      final dot = image.path.lastIndexOf('.');
      final ext = dot >= 0 ? image.path.substring(dot) : '.jpg';
      final objectPath =
          '$uid/food_${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}$ext';
      await supabase.storage.from(_bucket).upload(objectPath, image);
      imageUrls.add(supabase.storage.from(_bucket).getPublicUrl(objectPath));
    }

    final inserted = await supabase
        .from('food_posts')
        .insert({
          'author_id': uid,
          'community': community,
          'store_name': storeName,
          'body': body,
          'location': location,
          'image_urls': imageUrls,
        })
        .select()
        .single();
    return FoodPost.fromMap(inserted);
  }

  Future<List<FoodPost>> search(String query, {String? community}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    var builder = supabase
        .from('food_posts')
        .select()
        .or('store_name.ilike.%$q%,body.ilike.%$q%,location.ilike.%$q%');
    if (community != null) builder = builder.eq('community', community);
    final rows = await builder.order('created_at', ascending: false);
    return (rows as List)
        .map((e) => FoodPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) async {
    await supabase.from('food_posts').delete().eq('id', id);
  }
}
