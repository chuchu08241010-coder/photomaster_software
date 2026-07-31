import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

const String _bucket = 'post-images';

/// 跨平台上传一张图片到 post-images 桶，返回公开 URL。
/// 使用字节流 uploadBinary —— 手机与网页(H5)都支持（避免 dart:io File 在 web 不可用）。
Future<String> uploadImage(XFile image, {required String prefix}) async {
  final uid = currentUserId;
  if (uid == null) throw StateError('未登录');

  final name = image.name;
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot).toLowerCase() : '.jpg';
  final bytes = await image.readAsBytes();
  final objectPath =
      '$uid/${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}$ext';

  await supabase.storage.from(_bucket).uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(contentType: image.mimeType ?? _mime(ext)),
      );
  return supabase.storage.from(_bucket).getPublicUrl(objectPath);
}

String _mime(String ext) {
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}
