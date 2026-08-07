import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 一张图片的画质与统计指标（全部端侧计算，不上传）。
class ImageMetrics {
  const ImageMetrics({
    required this.width,
    required this.height,
    required this.lumaHist,
    required this.rHist,
    required this.gHist,
    required this.bHist,
    required this.waveform,
    required this.meanBrightness,
    required this.overExposed,
    required this.underExposed,
    required this.sharpness,
    required this.sharpnessScore,
    required this.avgR,
    required this.avgG,
    required this.avgB,
    required this.qualityScore,
    required this.elapsedMs,
  });

  final int width;
  final int height;
  final List<int> lumaHist; // 256
  final List<int> rHist;
  final List<int> gHist;
  final List<int> bHist;
  final List<int> waveform; // 256*256，[luma*256 + col] 计数（亮度波形）
  final double meanBrightness; // 0..1
  final double overExposed; // 高光溢出占比 0..1
  final double underExposed; // 暗部死黑占比 0..1
  final double sharpness; // 拉普拉斯方差（原始值）
  final double sharpnessScore; // 0..100
  final double avgR;
  final double avgG;
  final double avgB;
  final int qualityScore; // 0..100 综合
  final int elapsedMs;

  /// 粗略色温估计（K）与倾向。
  double get colorTempK {
    if (avgR <= 0) return 6500;
    final k = 6500.0 * (avgB / avgR);
    return k.clamp(2000, 12000);
  }

  String get colorTempLabel {
    final k = colorTempK;
    if (k < 5200) return '偏暖 (~${k.round()}K)';
    if (k > 7000) return '偏冷 (~${k.round()}K)';
    return '中性 (~${k.round()}K)';
  }
}

/// 端侧分析：解码→缩放→逐像素统计直方图/曝光/清晰度。
/// 缩放到最长边 640 以保证速度（手机/网页都能秒级完成）。
ImageMetrics? analyzeBytes(Uint8List bytes) {
  final sw = Stopwatch()..start();
  var image = img.decodeImage(bytes);
  if (image == null) return null;

  const maxDim = 640;
  if (image.width > maxDim || image.height > maxDim) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxDim)
        : img.copyResize(image, height: maxDim);
  }

  final w = image.width;
  final h = image.height;
  final luma = Uint8List(w * h);
  final lumaHist = List<int>.filled(256, 0);
  final rHist = List<int>.filled(256, 0);
  final gHist = List<int>.filled(256, 0);
  final bHist = List<int>.filled(256, 0);
  final waveform = List<int>.filled(256 * 256, 0);

  double sumR = 0, sumG = 0, sumB = 0;
  int i = 0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final l = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
      luma[i++] = l;
      lumaHist[l]++;
      rHist[r]++;
      gHist[g]++;
      bHist[b]++;
      final col = w > 1 ? (x * 255 ~/ (w - 1)) : 0;
      waveform[l * 256 + col]++;
      sumR += r;
      sumG += g;
      sumB += b;
    }
  }
  final n = w * h;

  // 拉普拉斯方差（清晰度/对焦程度）
  double s1 = 0, s2 = 0;
  int cnt = 0;
  for (int y = 1; y < h - 1; y++) {
    for (int x = 1; x < w - 1; x++) {
      final idx = y * w + x;
      final lap = (4 * luma[idx] -
              luma[idx - 1] -
              luma[idx + 1] -
              luma[idx - w] -
              luma[idx + w])
          .toDouble();
      s1 += lap;
      s2 += lap * lap;
      cnt++;
    }
  }
  final lapMean = cnt > 0 ? s1 / cnt : 0;
  final lapVar = cnt > 0 ? (s2 / cnt - lapMean * lapMean) : 0.0;

  int over = 0, under = 0;
  for (int l = 250; l < 256; l++) {
    over += lumaHist[l];
  }
  for (int l = 0; l <= 5; l++) {
    under += lumaHist[l];
  }

  final meanBrightness =
      (List.generate(256, (l) => l * lumaHist[l]).reduce((a, b) => a + b)) /
          n /
          255.0;
  final overExposed = over / n;
  final underExposed = under / n;

  // 清晰度归一化评分（sqrt 更符合感知）
  final sharpnessScore =
      (math.sqrt(lapVar) / math.sqrt(1500) * 100).clamp(0, 100).toDouble();

  // 曝光评分：亮度接近 0.5 且裁剪少则高
  final expBalance = 1 - (meanBrightness - 0.5).abs() * 2; // 0..1
  final clipPenalty = (overExposed + underExposed).clamp(0, 1);
  final exposureScore = (expBalance * (1 - clipPenalty)).clamp(0, 1) * 100;

  final quality =
      (sharpnessScore * 0.55 + exposureScore * 0.45).round().clamp(0, 100);

  sw.stop();
  return ImageMetrics(
    width: w,
    height: h,
    lumaHist: lumaHist,
    rHist: rHist,
    gHist: gHist,
    bHist: bHist,
    waveform: waveform,
    meanBrightness: meanBrightness,
    overExposed: overExposed,
    underExposed: underExposed,
    sharpness: lapVar.toDouble(),
    sharpnessScore: sharpnessScore,
    avgR: sumR / n,
    avgG: sumG / n,
    avgB: sumB / n,
    qualityScore: quality,
    elapsedMs: sw.elapsedMilliseconds,
  );
}
