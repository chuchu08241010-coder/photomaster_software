import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

import 'exif_info.dart';

/// 图片本地分析：EXIF 拍摄参数解析 + 端侧图像标签（自动 tag）。
/// 全部离线，不上传图片。网页端 ML Kit 不可用会自动跳过。
class ImageAnalysis {
  /// 读取一张图的拍摄参数。
  static Future<ExifInfo?> readExif(XFile file) async {
    final data = await readExifFromBytes(await file.readAsBytes());
    if (data.isEmpty) return null;

    String? raw(String key) {
      final v = data[key]?.printable.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final info = ExifInfo(
      model: raw('Image Model'),
      aperture: _formatAperture(raw('EXIF FNumber')),
      shutter: _formatShutter(raw('EXIF ExposureTime')),
      iso: raw('EXIF ISOSpeedRatings'),
      focalLength: _formatFocal(raw('EXIF FocalLength')),
    );
    return info.isEmpty ? null : info;
  }

  /// 端侧图像标签，返回建议标签（英文，用户可编辑）。网页端返回空。
  static Future<List<String>> labelImage(XFile file) async {
    if (kIsWeb) return const []; // ML Kit 不支持 web
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.7),
    );
    try {
      final input = InputImage.fromFilePath(file.path);
      final labels = await labeler.processImage(input);
      return labels.map((l) => l.label).toList();
    } catch (_) {
      return const [];
    } finally {
      await labeler.close();
    }
  }

  static double? _ratioToDouble(String? s) {
    if (s == null) return null;
    if (s.contains('/')) {
      final parts = s.split('/');
      final a = double.tryParse(parts[0].trim());
      final b = double.tryParse(parts[1].trim());
      if (a != null && b != null && b != 0) return a / b;
      return null;
    }
    return double.tryParse(s);
  }

  static String? _formatAperture(String? s) {
    final v = _ratioToDouble(s);
    if (v == null) return s == null ? null : 'f/$s';
    return 'f/${_trim(v)}';
  }

  static String? _formatShutter(String? s) {
    if (s == null) return null;
    // 常见为分数如 1/125，直接加单位；大于等于 1 秒的数字也加 s。
    if (s.contains('/')) return '${s}s';
    final v = double.tryParse(s);
    return v == null ? '${s}s' : '${_trim(v)}s';
  }

  static String? _formatFocal(String? s) {
    final v = _ratioToDouble(s);
    if (v == null) return s == null ? null : '${s}mm';
    return '${_trim(v)}mm';
  }

  static String _trim(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
