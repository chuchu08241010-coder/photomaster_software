import 'package:flutter/material.dart';

import '../profile/widgets/author_header.dart';
import 'comment_repository.dart';

/// 打开评论面板（底部弹出）。
Future<void> showCommentsSheet(
  BuildContext context, {
  required String itemType,
  required String itemId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CommentsSheet(itemType: itemType, itemId: itemId),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.itemType, required this.itemId});

  final String itemType;
  final String itemId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _repo = CommentRepository();
  final _controller = TextEditingController();
  late Future<List<Comment>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.list(widget.itemType, widget.itemId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.add(widget.itemType, widget.itemId, text);
      _controller.clear();
      setState(() {
        _future = _repo.list(widget.itemType, widget.itemId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('评论失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('评论', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Comment>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('加载失败：${snapshot.error}'));
                    }
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) {
                      return const Center(child: Text('还没有评论，来抢沙发'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthorHeader(
                                  authorId: c.authorId, time: c.createdAt),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 44),
                                child: Text(c.body),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '写评论…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
