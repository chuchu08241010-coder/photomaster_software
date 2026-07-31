import 'dart:io';

import '../../../core/supabase/supabase_client.dart';

/// 漂流瓶，对应 public.drift_bottles。
class DriftBottle {
  const DriftBottle({
    required this.id,
    required this.authorId,
    required this.body,
    required this.imageUrl,
  });

  final String id;
  final String authorId;
  final String body;
  final String? imageUrl;

  factory DriftBottle.fromMap(Map<String, dynamic> map) => DriftBottle(
        id: map['id'] as String,
        authorId: map['author_id'] as String,
        body: (map['body'] as String?) ?? '',
        imageUrl: map['image_url'] as String?,
      );
}

class DriftBottleRepository {
  static const String _bucket = 'post-images';

  /// 随机捞一个（可能是自己的）。无瓶时返回 null。
  Future<DriftBottle?> random() async {
    final res = await supabase.rpc('random_bottle');
    final list = res as List;
    if (list.isEmpty) return null;
    return DriftBottle.fromMap(list.first as Map<String, dynamic>);
  }

  /// 扔一个漂流瓶（文字 + 可选图片）。
  Future<DriftBottle> create({required String body, File? image}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    String? imageUrl;
    if (image != null) {
      final dot = image.path.lastIndexOf('.');
      final ext = dot >= 0 ? image.path.substring(dot) : '.jpg';
      final objectPath =
          '$uid/bottle_${DateTime.now().millisecondsSinceEpoch}$ext';
      await supabase.storage.from(_bucket).upload(objectPath, image);
      imageUrl = supabase.storage.from(_bucket).getPublicUrl(objectPath);
    }
    final inserted = await supabase
        .from('drift_bottles')
        .insert({'author_id': uid, 'body': body, 'image_url': imageUrl})
        .select()
        .single();
    return DriftBottle.fromMap(inserted);
  }
}
