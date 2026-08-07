import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/picked_image.dart';
import 'data/campaign.dart';

/// 发起一个主题投稿活动：1:1 海报 + 标题 + 规则说明。
class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _repo = CampaignRepository();
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _rulesController = TextEditingController();

  XFile? _poster;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _poster = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('请填写活动标题');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.createCampaign(
        title: _titleController.text.trim(),
        rules: _rulesController.text.trim(),
        poster: _poster,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('发布失败：$e');
      setState(() => _submitting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('发起活动'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _save,
            child: const Text('发布'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('活动海报（1:1）',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: InkWell(
                onTap: _pickPoster,
                borderRadius: BorderRadius.circular(14),
                child: _poster == null
                    ? Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: scheme.outlineVariant),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40),
                            SizedBox(height: 8),
                            Text('选择一张封面海报'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: PickedImageView(_poster!),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '活动标题',
                hintText: '如：一起拍城市的夜',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rulesController,
              maxLines: 8,
              minLines: 5,
              decoration: const InputDecoration(
                labelText: '规则 / 说明',
                hintText: '介绍活动主题、投稿要求、截止时间等…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            if (_submitting)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.campaign_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('发布活动'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
