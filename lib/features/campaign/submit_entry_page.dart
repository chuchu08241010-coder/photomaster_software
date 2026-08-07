import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/network_photo.dart';
import '../../core/widgets/picked_image.dart';
import 'data/campaign.dart';

/// 投稿页：新建或编辑自己的一条投稿（选图 + 文案）。
class SubmitEntryPage extends StatefulWidget {
  const SubmitEntryPage({
    super.key,
    required this.campaignId,
    this.editing,
  });

  final String campaignId;
  final CampaignEntry? editing;

  @override
  State<SubmitEntryPage> createState() => _SubmitEntryPageState();
}

class _SubmitEntryPageState extends State<SubmitEntryPage> {
  final _repo = CampaignRepository();
  final _picker = ImagePicker();
  final _captionController = TextEditingController();

  // 编辑时：保留的原图 URL；新选的本地图。
  late final List<String> _keepUrls;
  final List<XFile> _newImages = [];
  bool _submitting = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _keepUrls = List.of(widget.editing?.imageUrls ?? const []);
    _captionController.text = widget.editing?.caption ?? '';
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) setState(() => _newImages.addAll(picked));
  }

  Future<void> _save() async {
    if (_keepUrls.isEmpty && _newImages.isEmpty) {
      _snack('请至少选择一张照片');
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await _repo.updateEntry(
          entryId: widget.editing!.id,
          keepUrls: _keepUrls,
          newImages: _newImages,
          caption: _captionController.text.trim(),
        );
      } else {
        await _repo.createEntry(
          campaignId: widget.campaignId,
          images: _newImages,
          caption: _captionController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('提交失败：$e');
      setState(() => _submitting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑投稿' : '我要投稿'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _save,
            child: const Text('提交'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var i = 0; i < _keepUrls.length; i++)
                  _Thumb(
                    child: NetworkPhoto(_keepUrls[i]),
                    onRemove: () => setState(() => _keepUrls.removeAt(i)),
                  ),
                for (var i = 0; i < _newImages.length; i++)
                  _Thumb(
                    child: PickedImageView(_newImages[i]),
                    onRemove: () => setState(() => _newImages.removeAt(i)),
                  ),
                InkWell(
                  onTap: _pick,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '文案（可选）',
                hintText: '聊聊这组照片的故事…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_submitting)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(_isEdit ? '保存修改' : '提交投稿'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.onRemove});
  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
