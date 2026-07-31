import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import 'comment_repository.dart';
import 'comments_sheet.dart';
import 'favorite_repository.dart';

/// 帖子底部操作条：收藏(计数) + 评论(计数) + 删除(仅自己的)。
/// 摄影/文字/美食三类卡片通用。
class PostActionsBar extends StatefulWidget {
  const PostActionsBar({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.authorId,
    required this.initiallyFavorited,
    required this.onDelete,
    this.onDeleted,
  });

  final String itemType;
  final String itemId;
  final String authorId;
  final bool initiallyFavorited;

  /// 执行删除（调用对应仓储）。
  final Future<void> Function() onDelete;

  /// 删除成功后通知外部刷新列表。
  final VoidCallback? onDeleted;

  @override
  State<PostActionsBar> createState() => _PostActionsBarState();
}

class _PostActionsBarState extends State<PostActionsBar> {
  final _favRepo = FavoriteRepository();
  final _commentRepo = CommentRepository();

  late bool _favorited = widget.initiallyFavorited;
  int? _favCount;
  int? _commentCount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final f = await _favRepo.count(widget.itemType, widget.itemId);
      final c = await _commentRepo.count(widget.itemType, widget.itemId);
      if (mounted) setState(() {
        _favCount = f;
        _commentCount = c;
      });
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (_busy) return;
    final next = !_favorited;
    setState(() {
      _favorited = next;
      _busy = true;
      if (_favCount != null) _favCount = _favCount! + (next ? 1 : -1);
    });
    try {
      await _favRepo.setFavorite(
        itemType: widget.itemType,
        itemId: widget.itemId,
        value: next,
      );
    } catch (e) {
      setState(() {
        _favorited = !next;
        if (_favCount != null) _favCount = _favCount! + (next ? -1 : 1);
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments() async {
    await showCommentsSheet(
      context,
      itemType: widget.itemType,
      itemId: widget.itemId,
    );
    final c = await _commentRepo.count(widget.itemType, widget.itemId);
    if (mounted) setState(() => _commentCount = c);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这条帖子？'),
        content: const Text('删除后不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.onDelete();
      widget.onDeleted?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = widget.authorId == currentUserId;
    return Row(
      children: [
        TextButton.icon(
          onPressed: _toggleFav,
          icon: Icon(
            _favorited ? Icons.bookmark : Icons.bookmark_border,
            color: _favorited ? theme.colorScheme.primary : null,
          ),
          label: Text(_favCount?.toString() ?? '收藏'),
        ),
        TextButton.icon(
          onPressed: _openComments,
          icon: const Icon(Icons.mode_comment_outlined),
          label: Text(_commentCount?.toString() ?? '评论'),
        ),
        const Spacer(),
        if (isMine)
          IconButton(
            onPressed: _confirmDelete,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: '删除',
          ),
      ],
    );
  }
}
