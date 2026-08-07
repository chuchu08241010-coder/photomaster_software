import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

const String _bucket = 'post-images';
const int _maxDimension = 1280; // 上传前压缩到最长边不超过此值
const int _jpegQuality = 78;

/// 跨平台上传一张图片到 post-images 桶，返回公开 URL。
/// 上传前压缩（解码→缩放→重编码 JPEG），大幅减小体积、加快上传与显示。
/// 无法解码（如部分 HEIC）时回退上传原始字节。uploadBinary 手机+网页都支持。
Future<String> uploadImage(XFile image, {required String prefix}) async {
  final uid = currentUserId;
  if (uid == null) throw StateError('未登录');

  final original = await image.readAsBytes();
  final result = _compress(original, image.name);

  final objectPath =
      '$uid/${prefix}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(100000)}${result.ext}';

  await supabase.storage.from(_bucket).uploadBinary(
        objectPath,
        result.bytes,
        fileOptions: FileOptions(contentType: result.mime),
      );
  return supabase.storage.from(_bucket).getPublicUrl(objectPath);
}

/// 删除一组公开 URL 对应的存储文件（清理孤儿文件，避免删帖后仍占空间）。
/// 只处理属于本桶的 URL；任何异常都吞掉，不影响主删除流程。
Future<void> deleteStorageByUrls(Iterable<String> urls) async {
  const marker = '/object/public/$_bucket/';
  final paths = <String>[];
  for (final url in urls) {
    final i = url.indexOf(marker);
    if (i < 0) continue;
    var path = url.substring(i + marker.length);
    final q = path.indexOf('?');
    if (q >= 0) path = path.substring(0, q);
    if (path.isNotEmpty) paths.add(Uri.decodeComponent(path));
  }
  if (paths.isEmpty) return;
  try {
    await supabase.storage.from(_bucket).remove(paths);
  } catch (_) {
    // 忽略：文件可能已不存在
  }
}

class _Compressed {
  const _Compressed(this.bytes, this.ext, this.mime);
  final Uint8List bytes;
  final String ext;
  final String mime;
}

/// 压缩图片；解码失败或压缩后更大则回退原字节。
_Compressed _compress(Uint8List original, String name) {
  try {
    var decoded = img.decodeImage(original);
    if (decoded == null) {
      final e = _extOf(name);
      return _Compressed(original, e, _mime(e));
    }
    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      decoded = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: _maxDimension)
          : img.copyResize(decoded, height: _maxDimension);
    }
    final jpg = img.encodeJpg(decoded, quality: _jpegQuality);
    if (jpg.length >= original.length) {
      final e = _extOf(name);
      return _Compressed(original, e, _mime(e));
    }
    return _Compressed(jpg, '.jpg', 'image/jpeg');
  } catch (_) {
    final e = _extOf(name);
    return _Compressed(original, e, _mime(e));
  }
}

String _extOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot >= 0 ? name.substring(dot).toLowerCase() : '.jpg';
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
