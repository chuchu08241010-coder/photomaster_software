import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/picked_image.dart';
import 'data/image_metrics.dart';

/// 竞品 A/B 画质对比：选两张图，端侧跑客观指标，逐项对比并给出结论。
/// 对应影像评测里的「竞品对比 / 可量化需求清单」。
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final _picker = ImagePicker();

  XFile? _aFile, _bFile;
  ImageMetrics? _a, _b;
  bool _busyA = false, _busyB = false;

  Future<void> _pick(bool isA) async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      if (isA) {
        _aFile = x;
        _busyA = true;
        _a = null;
      } else {
        _bFile = x;
        _busyB = true;
        _b = null;
      }
    });
    try {
      final Uint8List bytes = await x.readAsBytes();
      final m = await Future(() => analyzeBytes(bytes));
      if (!mounted) return;
      setState(() {
        if (isA) {
          _a = m;
          _busyA = false;
        } else {
          _b = m;
          _busyB = false;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isA) _busyA = false;
          if (isB(isA)) _busyB = false;
        });
      }
    }
  }

  bool isB(bool isA) => !isA;

  @override
  Widget build(BuildContext context) {
    final ready = _a != null && _b != null;
    return Scaffold(
      appBar: AppBar(title: const Text('竞品对比')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _slot('样张 A', _aFile, _busyA, () => _pick(true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _slot('样张 B', _bFile, _busyB, () => _pick(false)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ready) ...[
            _conclusion(_a!, _b!),
            const SizedBox(height: 16),
            _table(_a!, _b!),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '分别选择 A、B 两张样张，将逐项对比清晰度、噪声、对比度、'
                '动态范围、曝光等客观指标（全程端侧计算，不上传）。',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slot(String title, XFile? file, bool busy, VoidCallback onPick) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPick,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      child: const Center(
                          child: Icon(Icons.add_photo_alternate_outlined,
                              size: 36)),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PickedImageView(file),
                        if (busy)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _conclusion(ImageMetrics a, ImageMetrics b) {
    final theme = Theme.of(context);
    final parts = <String>[];
    void cmp(String name, double av, double bv, bool higherBetter) {
      if ((av - bv).abs() < 1e-6) return;
      final aWin = higherBetter ? av > bv : av < bv;
      parts.add('${aWin ? 'A' : 'B'} $name');
    }

    cmp('更锐', a.sharpnessScore, b.sharpnessScore, true);
    cmp('更干净(噪声低)', a.noiseSigma, b.noiseSigma, false);
    cmp('动态范围更大', a.dynamicRangeStops, b.dynamicRangeStops, true);
    cmp('对比度更高', a.rmsContrast, b.rmsContrast, true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 20),
              const SizedBox(width: 6),
              Text('综合评分  A ${a.qualityScore} : ${b.qualityScore} B',
                  style: theme.textTheme.titleMedium),
            ],
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(parts.join('　·　'),
                style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _table(ImageMetrics a, ImageMetrics b) {
    final rows = <_Row>[
      _Row('综合评分', a.qualityScore.toDouble(), b.qualityScore.toDouble(),
          '${a.qualityScore}', '${b.qualityScore}', true),
      _Row('清晰度', a.sharpnessScore, b.sharpnessScore,
          a.sharpnessScore.toStringAsFixed(0),
          b.sharpnessScore.toStringAsFixed(0), true),
      _Row('Tenengrad', a.tenengrad, b.tenengrad,
          a.tenengrad.toStringAsFixed(0), b.tenengrad.toStringAsFixed(0), true),
      _Row('噪声 σ', a.noiseSigma, b.noiseSigma, a.noiseSigma.toStringAsFixed(2),
          b.noiseSigma.toStringAsFixed(2), false),
      _Row('对比度', a.rmsContrast, b.rmsContrast,
          '${(a.rmsContrast * 100).toStringAsFixed(0)}%',
          '${(b.rmsContrast * 100).toStringAsFixed(0)}%', true),
      _Row('动态范围', a.dynamicRangeStops, b.dynamicRangeStops,
          '${a.dynamicRangeStops.toStringAsFixed(1)}档',
          '${b.dynamicRangeStops.toStringAsFixed(1)}档', true),
      _Row('高光溢出', a.overExposed, b.overExposed,
          '${(a.overExposed * 100).toStringAsFixed(1)}%',
          '${(b.overExposed * 100).toStringAsFixed(1)}%', false),
      _Row('暗部死黑', a.underExposed, b.underExposed,
          '${(a.underExposed * 100).toStringAsFixed(1)}%',
          '${(b.underExposed * 100).toStringAsFixed(1)}%', false),
      _Row('平均亮度', 0, 0,
          '${(a.meanBrightness * 100).toStringAsFixed(0)}%',
          '${(b.meanBrightness * 100).toStringAsFixed(0)}%', null),
      _Row('色温', 0, 0, a.colorTempLabel, b.colorTempLabel, null),
    ];
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('指标')),
                Expanded(
                    flex: 2,
                    child: Text('A', textAlign: TextAlign.center)),
                Expanded(
                    flex: 2,
                    child: Text('B', textAlign: TextAlign.center)),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _rowWidget(rows[i], i.isOdd),
        ],
      ),
    );
  }

  Widget _rowWidget(_Row r, bool striped) {
    final theme = Theme.of(context);
    int winner = 0; // 0 none, 1 A, 2 B
    if (r.higherBetter != null && (r.aNum - r.bNum).abs() > 1e-6) {
      final aWin = r.higherBetter! ? r.aNum > r.bNum : r.aNum < r.bNum;
      winner = aWin ? 1 : 2;
    }
    TextStyle styleFor(bool isWinner) => TextStyle(
          fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
          color: isWinner ? Colors.green.shade700 : theme.colorScheme.onSurface,
        );
    return Container(
      color: striped
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(r.label,
                  style: TextStyle(color: theme.colorScheme.outline))),
          Expanded(
            flex: 2,
            child: Text(
              winner == 1 ? '▲ ${r.aStr}' : r.aStr,
              textAlign: TextAlign.center,
              style: styleFor(winner == 1),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              winner == 2 ? '▲ ${r.bStr}' : r.bStr,
              textAlign: TextAlign.center,
              style: styleFor(winner == 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  _Row(this.label, this.aNum, this.bNum, this.aStr, this.bStr,
      this.higherBetter);
  final String label;
  final double aNum;
  final double bNum;
  final String aStr;
  final String bStr;
  final bool? higherBetter; // null = 不判胜负
}
