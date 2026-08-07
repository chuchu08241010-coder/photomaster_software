import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/storage_upload.dart';
import '../../../core/supabase/supabase_client.dart';
import 'exif_info.dart';
import 'photo_post.dart';

/// 摄影帖仓储：负责图片上传与帖子的读写。
class PhotoPostRepository {

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
    required List<XFile> images,
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
      imageUrls.add(await uploadImage(image, prefix: 'photo'));
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

  /// 删除自己的帖子（RLS 保证），并清理其图片文件。
  Future<void> delete(String id) async {
    final row = await supabase
        .from('photo_posts')
        .select('image_urls')
        .eq('id', id)
        .maybeSingle();
    if (row != null) {
      final urls = ((row['image_urls'] as List?) ?? const [])
          .map((e) => e.toString());
      await deleteStorageByUrls(urls);
    }
    await supabase.from('photo_posts').delete().eq('id', id);
  }

  /// 编辑自己的摄影帖：keepUrls 保留的原图，newImages 新增图。
  /// 被移除的原图会从存储中一并删除。
  Future<void> updatePost({
    required String id,
    required List<String> keepUrls,
    required List<XFile> newImages,
    required String caption,
    required List<String> tags,
    String? location,
    ExifInfo? exif,
  }) async {
    final current = await supabase
        .from('photo_posts')
        .select('image_urls')
        .eq('id', id)
        .maybeSingle();
    final oldUrls = ((current?['image_urls'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();

    final urls = [...keepUrls];
    for (final image in newImages) {
      urls.add(await uploadImage(image, prefix: 'photo'));
    }
    await supabase.from('photo_posts').update({
      'caption': caption,
      'tags': tags,
      'location': location,
      'image_urls': urls,
      'exif': (exif == null || exif.isEmpty) ? null : exif.toJson(),
    }).eq('id', id);

    // 清理被移除的原图。
    await deleteStorageByUrls(oldUrls.difference(keepUrls.toSet()));
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
