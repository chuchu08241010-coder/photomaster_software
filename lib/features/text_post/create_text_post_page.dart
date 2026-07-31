import 'package:flutter/material.dart';

import 'data/text_post.dart';

/// 发文字帖：选类型 + 标题 + 正文 + 地址（可选）。
class CreateTextPostPage extends StatefulWidget {
  const CreateTextPostPage({super.key});

  @override
  State<CreateTextPostPage> createState() => _CreateTextPostPageState();
}

class _CreateTextPostPageState extends State<CreateTextPostPage> {
  final _repo = TextPostRepository();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _locationController = TextEditingController();

  String _type = kTextPostTypes.first.$1;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty &&
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写标题或正文')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.create(
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
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
        title: const Text('发文字帖'),
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
            const Text('类型', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in kTextPostTypes)
                  ChoiceChip(
                    label: Text(t.$2),
                    selected: _type == t.$1,
                    onSelected: (_) => setState(() => _type = t.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '正文',
                hintText: '详细说说…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '地址（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            if (_submitting)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
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
