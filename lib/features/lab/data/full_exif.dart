import 'dart:typed_data';

import 'package:exif/exif.dart';

/// 一条 EXIF 展示项。
class ExifEntry {
  const ExifEntry(this.label, this.value);
  final String label;
  final String value;
}

/// 完整解析常用 EXIF 拍摄参数（型号/镜头/曝光三要素/白平衡/测光/GPS 等）。
Future<List<ExifEntry>> readFullExif(Uint8List bytes) async {
  final data = await readExifFromBytes(bytes);
  final entries = <ExifEntry>[];

  String? raw(String key) {
    final v = data[key]?.printable.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  void add(String label, String key, {String Function(String)? fmt}) {
    final v = raw(key);
    if (v != null) entries.add(ExifEntry(label, fmt != null ? fmt(v) : v));
  }

  double? ratio(String s) {
    if (s.contains('/')) {
      final p = s.split('/');
      final a = double.tryParse(p[0].trim());
      final b = double.tryParse(p[1].trim());
      if (a != null && b != null && b != 0) return a / b;
      return null;
    }
    return double.tryParse(s);
  }

  String trimNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  add('相机品牌', 'Image Make');
  add('相机型号', 'Image Model');
  add('镜头', 'EXIF LensModel');
  add('光圈', 'EXIF FNumber', fmt: (s) {
    final v = ratio(s);
    return v == null ? s : 'f/${trimNum(v)}';
  });
  add('快门', 'EXIF ExposureTime', fmt: (s) => s.contains('/') ? '${s}s' : '${s}s');
  add('ISO', 'EXIF ISOSpeedRatings');
  add('焦距', 'EXIF FocalLength', fmt: (s) {
    final v = ratio(s);
    return v == null ? '${s}mm' : '${trimNum(v)}mm';
  });
  add('35mm 等效焦距', 'EXIF FocalLengthIn35mmFilm', fmt: (s) => '${s}mm');
  add('曝光补偿', 'EXIF ExposureBiasValue', fmt: (s) {
    final v = ratio(s);
    return v == null ? '${s}EV' : '${v >= 0 ? '+' : ''}${trimNum(v)}EV';
  });
  add('测光模式', 'EXIF MeteringMode');
  add('曝光模式', 'EXIF ExposureMode');
  add('曝光程序', 'EXIF ExposureProgram');
  add('白平衡', 'EXIF WhiteBalance');
  add('闪光灯', 'EXIF Flash');
  add('拍摄时间', 'EXIF DateTimeOriginal');
  add('软件', 'Image Software');
  add('GPS 纬度', 'GPS GPSLatitude');
  add('GPS 经度', 'GPS GPSLongitude');

  return entries;
}
