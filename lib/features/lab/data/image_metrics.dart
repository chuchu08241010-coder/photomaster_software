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
    required this.tenengrad,
    required this.noiseSigma,
    required this.rmsContrast,
    required this.dynamicRangeStops,
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
  final double tenengrad; // Tenengrad(Sobel 梯度能量均值)，越大越锐
  final double noiseSigma; // Immerkær 噪声估计(luma 单位)，越小越干净
  final double rmsContrast; // RMS 对比度 0..1
  final double dynamicRangeStops; // 有效动态范围(挡/stops)
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

  // 拉普拉斯方差(清晰度) + Tenengrad(Sobel 梯度能量) + Immerkær 噪声估计
  // 三者共用一遍 3x3 邻域扫描，不额外增加遍数。
  double s1 = 0, s2 = 0; // 拉普拉斯均值/平方和
  double tenSum = 0; // Sobel 梯度能量累加
  double noiseSum = 0; // Immerkær 噪声累加
  int cnt = 0;
  for (int y = 1; y < h - 1; y++) {
    for (int x = 1; x < w - 1; x++) {
      final idx = y * w + x;
      final c = luma[idx];
      final tl = luma[idx - w - 1];
      final tc = luma[idx - w];
      final tr = luma[idx - w + 1];
      final ml = luma[idx - 1];
      final mr = luma[idx + 1];
      final bl = luma[idx + w - 1];
      final bc = luma[idx + w];
      final br = luma[idx + w + 1];

      // 4 邻域拉普拉斯
      final lap = (4 * c - ml - mr - tc - bc).toDouble();
      s1 += lap;
      s2 += lap * lap;

      // Sobel 梯度 → Tenengrad
      final gx = (tr + 2 * mr + br) - (tl + 2 * ml + bl);
      final gy = (bl + 2 * bc + br) - (tl + 2 * tc + tr);
      tenSum += (gx * gx + gy * gy).toDouble();

      // Immerkær 噪声掩模 [[1,-2,1],[-2,4,-2],[1,-2,1]]
      final nm = (tl - 2 * tc + tr) +
          (-2 * ml + 4 * c - 2 * mr) +
          (bl - 2 * bc + br);
      noiseSum += nm.abs();
      cnt++;
    }
  }
  final lapMean = cnt > 0 ? s1 / cnt : 0;
  final lapVar = cnt > 0 ? (s2 / cnt - lapMean * lapMean) : 0.0;
  final tenengrad = cnt > 0 ? tenSum / cnt : 0.0;
  // Immerkær: sigma = sum|I*N| * sqrt(pi/2) / (6*(W-2)*(H-2))
  final noiseSigma =
      cnt > 0 ? noiseSum * math.sqrt(math.pi / 2) / (6 * cnt) : 0.0;

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

  // RMS 对比度 = 亮度标准差 / 255
  double lSum = 0, lSqSum = 0;
  for (int l = 0; l < 256; l++) {
    lSum += l * lumaHist[l];
    lSqSum += l * l * lumaHist[l];
  }
  final lMean = lSum / n;
  final lVar = (lSqSum / n - lMean * lMean).clamp(0, double.infinity);
  final rmsContrast = (math.sqrt(lVar) / 255.0).clamp(0, 1).toDouble();

  // 有效动态范围：取 0.5% 与 99.5% 分位的亮度，换算成档(stops)
  final lowCount = (n * 0.005).round();
  final highCount = (n * 0.995).round();
  int acc = 0, pLow = 0, pHigh = 255;
  for (int l = 0; l < 256; l++) {
    acc += lumaHist[l];
    if (pLow == 0 && acc >= lowCount) pLow = l;
    if (acc >= highCount) {
      pHigh = l;
      break;
    }
  }
  final dynamicRangeStops =
      (math.log((pHigh + 1) / (pLow + 1)) / math.ln2).clamp(0, 8).toDouble();

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
    tenengrad: tenengrad,
    noiseSigma: noiseSigma,
    rmsContrast: rmsContrast,
    dynamicRangeStops: dynamicRangeStops,
    avgR: sumR / n,
    avgG: sumG / n,
    avgB: sumB / n,
    qualityScore: quality,
    elapsedMs: sw.elapsedMilliseconds,
  );
}
