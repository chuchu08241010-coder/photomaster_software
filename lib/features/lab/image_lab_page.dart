import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/picked_image.dart';
import 'data/full_exif.dart';
import 'data/image_metrics.dart';
import 'widgets/analysis_charts.dart';

/// 「分析」板块：端侧画质分析 + 直方图/波形 + 深度 EXIF。
/// 全部本地计算，不上传图片。
class ImageLabPage extends StatefulWidget {
  const ImageLabPage({super.key});

  @override
  State<ImageLabPage> createState() => _ImageLabPageState();
}

class _ImageLabPageState extends State<ImageLabPage> {
  final _picker = ImagePicker();

  XFile? _picked;
  ImageMetrics? _metrics;
  List<ExifEntry> _exif = const [];
  bool _analyzing = false;
  bool _showAllHist = false;

  Future<void> _pick() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _picked = x;
      _analyzing = true;
      _metrics = null;
      _exif = const [];
    });
    try {
      final Uint8List bytes = await x.readAsBytes();
      final exif = await readFullExif(bytes);
      // 让出一帧，避免解码阻塞造成掉帧观感
      final metrics = await Future(() => analyzeBytes(bytes));
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _exif = exif;
        _analyzing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('分析失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画质分析'),
        actions: [
          if (_picked != null)
            IconButton(
              onPressed: _pick,
              icon: const Icon(Icons.refresh),
              tooltip: '换一张',
            ),
        ],
      ),
      body: _picked == null ? _empty() : _content(),
      floatingActionButton: _picked == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('选图分析'),
            ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('端侧画质分析', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '选一张照片，本地计算清晰度、曝光、色温、\nRGB 直方图、亮度波形，并解析完整 EXIF。\n（全程离线，不上传）',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('选择照片'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: PickedImageView(_picked!),
          ),
        ),
        const SizedBox(height: 16),
        if (_analyzing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_metrics != null) ...[
          _scoreCard(_metrics!),
          const SizedBox(height: 20),
          _sectionTitle('RGB 直方图'),
          HistogramChart(metrics: _metrics!),
          const SizedBox(height: 20),
          _sectionTitle('亮度波形'),
          WaveformView(metrics: _metrics!),
          const SizedBox(height: 20),
          _sectionTitle('拍摄参数 (EXIF)'),
          _exifList(),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('无法解码这张图片')),
          ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );

  Widget _scoreCard(ImageMetrics m) {
    final theme = Theme.of(context);
    Color scoreColor(int s) => s >= 75
        ? Colors.green
        : s >= 50
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m.qualityScore}',
                  style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: scoreColor(m.qualityScore))),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(' / 100  综合画质评分'),
              ),
              const Spacer(),
              Text('分析耗时 ${m.elapsedMs}ms',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('清晰度', m.sharpnessScore.toStringAsFixed(0)),
              _metricChip('平均亮度',
                  '${(m.meanBrightness * 100).toStringAsFixed(0)}%'),
              _metricChip('高光溢出',
                  '${(m.overExposed * 100).toStringAsFixed(1)}%'),
              _metricChip('暗部死黑',
                  '${(m.underExposed * 100).toStringAsFixed(1)}%'),
              _metricChip('色温', m.colorTempLabel),
              _metricChip('分析分辨率', '${m.width}×${m.height}'),
            ],
          ),
          const SizedBox(height: 8),
          Text('清晰度 = 拉普拉斯方差 ${m.sharpness.toStringAsFixed(0)}（值越大越锐/对焦越实）',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _metricChip(String k, String v) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _exifList() {
    if (_exif.isEmpty) {
      return Text('这张图片没有 EXIF 信息（可能被截图/编辑去除）',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.outline));
    }
    final show = _showAllHist ? _exif : _exif.take(8).toList();
    return Column(
      children: [
        ...show.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(e.label,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )),
        if (_exif.length > 8)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAllHist = !_showAllHist),
              child: Text(_showAllHist ? '收起' : '展开全部 (${_exif.length})'),
            ),
          ),
      ],
    );
  }
}
