import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/storage_upload.dart';
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
  /// 随机捞一个（可能是自己的）。无瓶时返回 null。
  Future<DriftBottle?> random() async {
    final res = await supabase.rpc('random_bottle');
    final list = res as List;
    if (list.isEmpty) return null;
    return DriftBottle.fromMap(list.first as Map<String, dynamic>);
  }

  /// 扔一个漂流瓶（文字 + 可选图片）。
  Future<DriftBottle> create({required String body, XFile? image}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    String? imageUrl;
    if (image != null) {
      imageUrl = await uploadImage(image, prefix: 'bottle');
    }
    final inserted = await supabase
        .from('drift_bottles')
        .insert({'author_id': uid, 'body': body, 'image_url': imageUrl})
        .select()
        .single();
    return DriftBottle.fromMap(inserted);
  }
}
