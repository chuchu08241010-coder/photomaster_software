import 'dart:io';

import '../../../core/supabase/supabase_client.dart';
import 'exif_info.dart';
import 'photo_post.dart';

/// 摄影帖仓储：负责图片上传与帖子的读写。
class PhotoPostRepository {
  static const String _bucket = 'post-images';

  /// 拉取时间线（按时间倒序）。
  Future<List<PhotoPost>> fetchTimeline({int limit = 50}) async {
    final rows = await supabase
        .from('photo_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => PhotoPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 拉取某作者的全部帖子（个人主页用）。
  Future<List<PhotoPost>> fetchByAuthor(String authorId) async {
    final rows = await supabase
        .from('photo_posts')
        .select()
        .eq('author_id', authorId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PhotoPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 按 id 批量拉取（我的收藏用）。
  Future<List<PhotoPost>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await supabase
        .from('photo_posts')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PhotoPost.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 发布一条摄影帖：先上传所有图片，再插入记录。
  Future<PhotoPost> createPost({
    required List<File> images,
    required String caption,
    required List<String> tags,
    String? location,
    ExifInfo? exif,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('未登录，无法发帖');
    }

    final imageUrls = <String>[];
    for (final image in images) {
      final dot = image.path.lastIndexOf('.');
      final ext = dot >= 0 ? image.path.substring(dot) : '.jpg';
      final objectPath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}$ext';
      await supabase.storage.from(_bucket).upload(objectPath, image);
      imageUrls.add(supabase.storage.from(_bucket).getPublicUrl(objectPath));
    }

    final inserted = await supabase
        .from('photo_posts')
        .insert({
          'author_id': userId,
          'caption': caption,
          'tags': tags,
          'location': location,
          'image_urls': imageUrls,
          'exif': (exif == null || exif.isEmpty) ? null : exif.toJson(),
        })
        .select()
        .single();

    return PhotoPost.fromMap(inserted);
  }

  /// 关键词搜索：匹配文案/地址（模糊）或标签（包含）。
  Future<List<PhotoPost>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final byText = await supabase
        .from('photo_posts')
        .select()
        .or('caption.ilike.%$q%,location.ilike.%$q%')
        .order('created_at', ascending: false);

    final byTag = await supabase
        .from('photo_posts')
        .select()
        .contains('tags', [q]).order('created_at', ascending: false);

    final merged = <String, PhotoPost>{};
    for (final row in [...(byText as List), ...(byTag as List)]) {
      final post = PhotoPost.fromMap(row as Map<String, dynamic>);
      merged[post.id] = post;
    }
    final list = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
