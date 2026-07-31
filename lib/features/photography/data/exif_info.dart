/// 拍摄参数（从图片 EXIF 本地解析）。
class ExifInfo {
  const ExifInfo({
    this.model,
    this.aperture,
    this.shutter,
    this.iso,
    this.focalLength,
  });

  final String? model; // 相机/手机型号
  final String? aperture; // 光圈，如 f/2.8
  final String? shutter; // 快门，如 1/125s
  final String? iso; // 感光度
  final String? focalLength; // 焦距，如 50mm

  bool get isEmpty =>
      (model == null || model!.isEmpty) &&
      (aperture == null || aperture!.isEmpty) &&
      (shutter == null || shutter!.isEmpty) &&
      (iso == null || iso!.isEmpty) &&
      (focalLength == null || focalLength!.isEmpty);

  Map<String, dynamic> toJson() => {
        if (model != null) 'model': model,
        if (aperture != null) 'aperture': aperture,
        if (shutter != null) 'shutter': shutter,
        if (iso != null) 'iso': iso,
        if (focalLength != null) 'focalLength': focalLength,
      };

  factory ExifInfo.fromJson(Map<String, dynamic> json) => ExifInfo(
        model: json['model'] as String?,
        aperture: json['aperture'] as String?,
        shutter: json['shutter'] as String?,
        iso: json['iso'] as String?,
        focalLength: json['focalLength'] as String?,
      );

  /// 汇总成一行便于展示，如：「Sony A7M4 · f/2.8 · 1/125s · ISO 400 · 50mm」
  String get summary {
    final parts = <String>[
      if (model != null && model!.isNotEmpty) model!,
      if (aperture != null && aperture!.isNotEmpty) aperture!,
      if (shutter != null && shutter!.isNotEmpty) shutter!,
      if (iso != null && iso!.isNotEmpty) 'ISO $iso',
      if (focalLength != null && focalLength!.isNotEmpty) focalLength!,
    ];
    return parts.join(' · ');
  }
}
