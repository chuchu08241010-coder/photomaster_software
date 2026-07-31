import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/picked_image.dart';
import 'data/profile.dart';

/// 编辑资料：设置昵称与头像。
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _repo = ProfileRepository();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();

  XFile? _avatarFile;
  String? _currentAvatarUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = await _repo.getMine();
    if (!mounted) return;
    setState(() {
      _nameController.text = me?.displayName ?? '';
      _currentAvatarUrl = me?.avatarUrl;
      _loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _avatarFile = x);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写昵称')));
      return;
    }
    setState(() => _saving = true);
    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _repo.uploadAvatar(_avatarFile!);
      }
      await _repo.upsert(
        displayName: _nameController.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: ClipOval(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: _avatarFile != null
                            ? PickedImageView(_avatarFile!)
                            : (_currentAvatarUrl != null &&
                                    _currentAvatarUrl!.isNotEmpty)
                                ? Image.network(_currentAvatarUrl!,
                                    fit: BoxFit.cover)
                                : ColoredBox(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Icon(Icons.add_a_photo_outlined,
                                        size: 32,
                                        color: theme
                                            .colorScheme.onPrimaryContainer),
                                  ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('点击更换头像',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ],
            ),
    );
  }
}
