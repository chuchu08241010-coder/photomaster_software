import 'image_metrics.dart';

/// 单项指标的解读结果。
enum Verdict { good, ok, poor, neutral }

class MetricReading {
  const MetricReading({
    required this.name,
    required this.value,
    required this.verdict,
    required this.verdictLabel,
    required this.meaning,
    required this.standard,
  });

  final String name; // 指标名
  final String value; // 你的数值
  final Verdict verdict; // 好/中/差/中性
  final String verdictLabel; // 评价词
  final String meaning; // 原理：这个数是什么
  final String standard; // 阈值/参考标准
}

/// 把一组指标翻译成“人能看懂”的解读（数值 + 评价 + 原理 + 参考阈值）。
List<MetricReading> interpret(ImageMetrics m) {
  MetricReading r(String name, String value, Verdict v, String label,
          String meaning, String standard) =>
      MetricReading(
        name: name,
        value: value,
        verdict: v,
        verdictLabel: label,
        meaning: meaning,
        standard: standard,
      );

  // 综合评分
  final q = m.qualityScore;
  final qv = q >= 75
      ? Verdict.good
      : q >= 50
          ? Verdict.ok
          : Verdict.poor;

  // 清晰度（0~100 归一化，来自拉普拉斯方差）
  final sh = m.sharpnessScore;
  final shv = sh >= 70
      ? Verdict.good
      : sh >= 40
          ? Verdict.ok
          : Verdict.poor;

  // 噪声 σ（越小越干净）
  final nz = m.noiseSigma;
  final nzv = nz < 2
      ? Verdict.good
      : nz <= 5
          ? Verdict.ok
          : Verdict.poor;

  // 对比度（RMS %）
  final ct = m.rmsContrast * 100;
  final ctv = ct < 12
      ? Verdict.poor
      : ct <= 45
          ? Verdict.good
          : Verdict.ok;

  // 动态范围（档）
  final dr = m.dynamicRangeStops;
  final drv = dr >= 6
      ? Verdict.good
      : dr >= 4
          ? Verdict.ok
          : Verdict.poor;

  // 平均亮度（%）——越接近中间越好
  final br = m.meanBrightness * 100;
  final brv = (br >= 40 && br <= 62)
      ? Verdict.good
      : (br >= 30 && br <= 72)
          ? Verdict.ok
          : Verdict.poor;

  // 高光溢出 / 暗部死黑（越少越好）
  Verdict clipV(double pct) => pct < 1
      ? Verdict.good
      : pct <= 5
          ? Verdict.ok
          : Verdict.poor;
  final over = m.overExposed * 100;
  final under = m.underExposed * 100;

  return [
    r('综合评分', '$q / 100', qv,
        q >= 75 ? '优秀' : (q >= 50 ? '中等' : '偏低'),
        '把清晰度与曝光按 55%/45% 加权得到的总分，用来快速判断整体成片质量。',
        '≥75 优秀 · 50~75 可用 · <50 偏低'),
    r('清晰度', sh.toStringAsFixed(0), shv,
        sh >= 70 ? '锐利' : (sh >= 40 ? '一般' : '偏糊'),
        '用拉普拉斯算子求图像二阶梯度的方差：边缘/细节越多，方差越大，代表对焦越实、越锐。',
        '≥70 锐利 · 40~70 一般 · <40 可能失焦/糊'),
    r('Tenengrad', m.tenengrad.toStringAsFixed(0), Verdict.neutral, '越大越锐',
        'Sobel 梯度能量的均值，是另一种锐度度量，和清晰度互为佐证，抗噪性略好。',
        '相对值：同题材下越大越锐（无固定阈值）'),
    r('噪声 σ', nz.toStringAsFixed(2), nzv,
        nz < 2 ? '干净' : (nz <= 5 ? '轻微' : '明显'),
        'Immerkær 噪声估计：用特定卷积核估计平坦区的随机噪声标准差（以亮度 0~255 为单位）。',
        '<2 干净 · 2~5 轻微 · >5 噪点明显（多见于高 ISO/暗光）'),
    r('对比度', '${ct.toStringAsFixed(0)}%', ctv,
        ct < 12 ? '平淡' : (ct <= 45 ? '适中' : '偏强'),
        'RMS 对比度 = 亮度标准差 / 255，反映明暗反差大小。',
        '<12% 偏平淡 · 12~45% 适中 · >45% 反差偏强'),
    r('动态范围', '${dr.toStringAsFixed(1)} 档', drv,
        dr >= 6 ? '宽广' : (dr >= 4 ? '中等' : '偏窄'),
        '取亮度 0.5%~99.5% 分位的跨度换算成“档(stop)”，衡量从暗到亮的层次范围。',
        '≥6 档 宽广 · 4~6 中等 · <4 偏窄（可能欠/过曝或雾感）'),
    r('平均亮度', '${br.toStringAsFixed(0)}%', brv,
        (br >= 40 && br <= 62) ? '合适' : (br < 40 ? '偏暗' : '偏亮'),
        '整幅画面的平均明度，反映整体曝光倾向。',
        '约 40~62% 较均衡 · 过低偏暗 · 过高偏亮'),
    r('高光溢出', '${over.toStringAsFixed(1)}%', clipV(over),
        over < 1 ? '很好' : (over <= 5 ? '注意' : '严重'),
        '亮度≥250 的像素占比：这些区域已“死白”、细节不可恢复。',
        '<1% 很好 · 1~5% 注意 · >5% 高光大面积过曝'),
    r('暗部死黑', '${under.toStringAsFixed(1)}%', clipV(under),
        under < 1 ? '很好' : (under <= 5 ? '注意' : '严重'),
        '亮度≤5 的像素占比：这些区域已“死黑”、暗部细节丢失。',
        '<1% 很好 · 1~5% 注意 · >5% 暗部大面积欠曝'),
    r('色温', m.colorTempLabel, Verdict.neutral, '白平衡倾向',
        '基于 R/G/B 均值的灰世界近似估计色温，判断画面偏暖(黄)或偏冷(蓝)。',
        '仅作参考；精确色温需从白点/CCT 曲线拟合'),
  ];
}
