import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 跨平台预览一个已选图片（image_picker 的 XFile）。
/// 用字节渲染（Image.memory），手机与网页(H5)都可用，避免 dart:io File。
class PickedImageView extends StatelessWidget {
  const PickedImageView(this.file, {super.key, this.fit = BoxFit.cover});

  final XFile file;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Color(0x11000000));
        }
        return Image.memory(snapshot.data!, fit: fit);
      },
    );
  }
}
