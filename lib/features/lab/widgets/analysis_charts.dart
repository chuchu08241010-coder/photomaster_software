import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/image_metrics.dart';

/// RGB 直方图（三通道叠加，plus 混合）。
class HistogramChart extends StatelessWidget {
  const HistogramChart({super.key, required this.metrics, this.height = 140});

  final ImageMetrics metrics;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _HistogramPainter(
          metrics.rHist,
          metrics.gHist,
          metrics.bHist,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter(this.r, this.g, this.b);
  final List<int> r, g, b;

  @override
  void paint(Canvas canvas, Size size) {
    int maxV = 1;
    for (final h in [r, g, b]) {
      for (var i = 1; i < 255; i++) {
        if (h[i] > maxV) maxV = h[i];
      }
    }
    void drawChannel(List<int> hist, Color color) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.65)
        ..blendMode = BlendMode.plus;
      final path = Path()..moveTo(0, size.height);
      for (var i = 0; i < 256; i++) {
        final x = i / 255 * size.width;
        final y = size.height - (hist[i] / maxV).clamp(0, 1) * size.height;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    drawChannel(r, const Color(0xFFFF4D4D));
    drawChannel(g, const Color(0xFF4DFF7A));
    drawChannel(b, const Color(0xFF4D9DFF));
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.r != r || old.g != g || old.b != b;
}

/// 亮度波形图（类似专业相机/后期软件的 waveform）。
class WaveformView extends StatefulWidget {
  const WaveformView({super.key, required this.metrics, this.height = 160});

  final ImageMetrics metrics;
  final double height;

  @override
  State<WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<WaveformView> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(WaveformView old) {
    super.didUpdateWidget(old);
    if (old.metrics != widget.metrics) _build();
  }

  Future<void> _build() async {
    final wf = widget.metrics.waveform; // [luma*256 + col]
    // 每列归一化，突出结构
    final colMax = List<int>.filled(256, 1);
    for (var l = 0; l < 256; l++) {
      for (var c = 0; c < 256; c++) {
        final v = wf[l * 256 + c];
        if (v > colMax[c]) colMax[c] = v;
      }
    }
    final rgba = Uint8List(256 * 256 * 4);
    for (var l = 0; l < 256; l++) {
      final iy = 255 - l; // 亮度高在上方
      for (var c = 0; c < 256; c++) {
        final v = wf[l * 256 + c];
        final inten = (v / colMax[c]).clamp(0.0, 1.0);
        final a = (inten * 255).round();
        final o = (iy * 256 + c) * 4;
        rgba[o] = (140 * inten).round(); // R
        rgba[o + 1] = (255 * inten).round(); // G (偏绿)
        rgba[o + 2] = (170 * inten).round(); // B
        rgba[o + 3] = a;
      }
    }
    final completer = await _decode(rgba);
    if (mounted) setState(() => _image = completer);
  }

  Future<ui.Image> _decode(Uint8List rgba) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, 256, 256, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _image == null
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : RawImage(image: _image, fit: BoxFit.fill),
    );
  }
}
