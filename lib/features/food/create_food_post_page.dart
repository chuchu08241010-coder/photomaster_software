import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../location/location_picker_page.dart';
import 'data/food_post.dart';

/// 发美食帖：选社区(推荐/避雷) + 店名 + 正文 + 地址 + 图片(可选)。
class CreateFoodPostPage extends StatefulWidget {
  const CreateFoodPostPage({super.key, this.initialCommunity = 'recommend'});

  final String initialCommunity;

  @override
  State<CreateFoodPostPage> createState() => _CreateFoodPostPageState();
}

class _CreateFoodPostPageState extends State<CreateFoodPostPage> {
  final _repo = FoodPostRepository();
  final _picker = ImagePicker();
  final _storeController = TextEditingController();
  final _bodyController = TextEditingController();
  final _locationController = TextEditingController();

  late String _community = widget.initialCommunity;
  final List<File> _images = [];
  bool _submitting = false;

  @override
  void dispose() {
    _storeController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _pickLocation() async {
    final current = _locationController.text.trim();
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerPage(initialText: current.isEmpty ? null : current),
      ),
    );
    if (result != null) setState(() => _locationController.text = result);
  }

  Future<void> _submit() async {
    if (_storeController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写店名或正文')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.create(
        community: _community,
        storeName: _storeController.text.trim(),
        body: _bodyController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        images: _images,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('发布失败：$e')));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发美食帖'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('发布'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: [
                for (final c in kFoodCommunities)
                  ButtonSegment(value: c.$1, label: Text(c.$2)),
              ],
              selected: {_community},
              onSelectionChanged: (s) => setState(() => _community = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: '店名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '正文',
                hintText: '好吃在哪 / 雷在哪…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: '地址（可选）',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: '地图选点',
                  onPressed: _pickLocation,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ImageStrip(
              images: _images,
              onAdd: _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),
            const SizedBox(height: 24),
            if (_submitting)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('发布'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var i = 0; i < images.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(images[i], fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        InkWell(
          onTap: onAdd,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_a_photo_outlined, size: 32),
          ),
        ),
      ],
    );
  }
}
