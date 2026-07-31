import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/picked_image.dart';
import 'data/drift_bottle.dart';

/// 扔一个漂流瓶：文字（居中展示）+ 可选图片（铺底）。
class CreateDriftBottlePage extends StatefulWidget {
  const CreateDriftBottlePage({super.key});

  @override
  State<CreateDriftBottlePage> createState() => _CreateDriftBottlePageState();
}

class _CreateDriftBottlePageState extends State<CreateDriftBottlePage> {
  final _repo = DriftBottleRepository();
  final _picker = ImagePicker();
  final _bodyController = TextEditingController();
  XFile? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _image = x);
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('写点什么再扔出去吧')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.create(body: _bodyController.text.trim(), image: _image);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('扔出失败：$e')));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扔一个漂流瓶'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('扔出'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _bodyController,
              maxLines: 5,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '想说的话',
                hintText: '写给捞到它的陌生人…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: InkWell(
                onTap: _pick,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: _image != null
                        ? PickedImageView(_image!)
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined, size: 40),
                                SizedBox(height: 8),
                                Text('可选：加一张铺底图'),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
