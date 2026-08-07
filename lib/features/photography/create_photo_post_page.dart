import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/network_photo.dart';
import '../../core/widgets/picked_image.dart';
import '../location/location_picker_page.dart';
import 'data/exif_info.dart';
import 'data/image_analysis.dart';
import 'data/photo_post.dart';
import 'data/photo_post_repository.dart';

/// 发摄影帖页面：选图 + 文案 + #标签 + 地址 → 上传发布。
/// 传入 editing 时为编辑模式。
class CreatePhotoPostPage extends StatefulWidget {
  const CreatePhotoPostPage({super.key, this.editing});

  final PhotoPost? editing;

  @override
  State<CreatePhotoPostPage> createState() => _CreatePhotoPostPageState();
}

class _CreatePhotoPostPageState extends State<CreatePhotoPostPage> {
  final _repo = PhotoPostRepository();
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _locationController = TextEditingController();

  final List<XFile> _images = [];
  final List<String> _keepUrls = [];
  bool _submitting = false;
  bool _analyzing = false;
  ExifInfo? _exif;
  final List<String> _suggestedTags = [];

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _captionController.text = e.caption;
      _tagsController.text = e.tags.join(' ');
      _locationController.text = e.location ?? '';
      _keepUrls.addAll(e.imageUrls);
      _exif = e.exif;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
      _analyze();
    }
  }

  /// 本地分析：读第一张图的 EXIF，并对图片做端侧标签识别得到建议 tag。
  Future<void> _analyze() async {
    if (_images.isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final exif = await ImageAnalysis.readExif(_images.first);
      final labelSet = <String>{};
      for (final img in _images.take(3)) {
        labelSet.addAll(await ImageAnalysis.labelImage(img));
      }
      if (!mounted) return;
      setState(() {
        _exif = exif;
        _suggestedTags
          ..clear()
          ..addAll(labelSet);
      });
    } catch (_) {
      // 分析失败不影响发帖
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _addTag(String tag) {
    final current = _tagsController.text.trim();
    final existing = _parseTags(current).toSet();
    if (existing.contains(tag)) return;
    _tagsController.text = current.isEmpty ? tag : '$current $tag';
    setState(() {});
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,，#]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_images.isEmpty && _keepUrls.isEmpty) {
      _showSnack('请至少选择一张照片');
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await _repo.updatePost(
          id: widget.editing!.id,
          keepUrls: _keepUrls,
          newImages: _images,
          caption: _captionController.text.trim(),
          tags: _parseTags(_tagsController.text),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          exif: _exif,
        );
      } else {
        await _repo.createPost(
          images: _images,
          caption: _captionController.text.trim(),
          tags: _parseTags(_tagsController.text),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          exif: _exif,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('发布失败：$e');
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑摄影帖' : '发摄影帖'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_isEdit ? '保存' : '发布'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ImagePickerGrid(
              images: _images,
              keepUrls: _keepUrls,
              onAdd: _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
              onRemoveUrl: (i) => setState(() => _keepUrls.removeAt(i)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '文案',
                hintText: '说点什么…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '用空格或逗号分隔，如：夜景 人像 街拍',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            if (_analyzing) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('正在本地识别拍摄参数与标签…'),
                ],
              ),
            ],
            if (_suggestedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('建议标签（点按添加）',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: -4,
                children: [
                  for (final tag in _suggestedTags)
                    ActionChip(
                      label: Text(tag),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: () => _addTag(tag),
                    ),
                ],
              ),
            ],
            if (_exif != null && !_exif!.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_exif!.summary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: '地址（可选）',
                hintText: '拍摄地点',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: '地图选点',
                  onPressed: _pickLocation,
                ),
              ),
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

class _ImagePickerGrid extends StatelessWidget {
  const _ImagePickerGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.keepUrls = const [],
    this.onRemoveUrl,
  });

  final List<XFile> images;
  final List<String> keepUrls;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int>? onRemoveUrl;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var i = 0; i < keepUrls.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkPhoto(keepUrls[i]),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemoveUrl?.call(i),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        for (var i = 0; i < images.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PickedImageView(images[i]),
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
