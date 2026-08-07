import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/image_viewer_page.dart';
import '../../core/widgets/network_photo.dart';
import '../../core/widgets/section_placeholder.dart';
import '../profile/widgets/author_header.dart';
import 'data/campaign.dart';
import 'submit_entry_page.dart';

/// 活动详情：海报 + 标题 + 规则说明 + 投稿入口 + 作品墙（可点赞、可改删自己的）。
class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  final _repo = CampaignRepository();
  late Future<List<CampaignEntry>> _future;
  List<CampaignEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CampaignEntry>> _load() async {
    final list = await _repo.fetchEntries(widget.campaign.id);
    _entries = list;
    return list;
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _submit({CampaignEntry? editing}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitEntryPage(
          campaignId: widget.campaign.id,
          editing: editing,
        ),
      ),
    );
    if (ok == true) _refresh();
  }

  Future<void> _delete(CampaignEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除投稿'),
        content: const Text('确定删除这条投稿吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteEntry(e.id);
      _refresh();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$err')));
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    final e = _entries[index];
    // 乐观更新
    setState(() {
      _entries[index] = e.copyWith(
        likedByMe: !e.likedByMe,
        likeCount: e.likeCount + (e.likedByMe ? -1 : 1),
      );
    });
    try {
      await _repo.toggleLike(e.id, currentlyLiked: e.likedByMe);
    } catch (_) {
      // 失败则回滚
      if (mounted) setState(() => _entries[index] = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submit(),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('我要投稿'),
      ),
      body: FutureBuilder<List<CampaignEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (c.posterUrl != null && c.posterUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onTap: () =>
                          ImageViewerPage.open(context, [c.posterUrl!], 0),
                      child: NetworkPhoto(c.posterUrl!),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(c.title, style: serifDisplay(size: 26)),
                ),
                if (!c.active)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('活动已结束',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                if (c.rules.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        c.rules,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Text('作品', style: serifDisplay(size: 20)),
                      const SizedBox(width: 8),
                      Text('${_entries.length}',
                          style: TextStyle(
                              color: theme.colorScheme.outline, fontSize: 15)),
                    ],
                  ),
                ),
                if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: SectionPlaceholder(
                      icon: Icons.photo_library_outlined,
                      title: '还没有作品',
                      subtitle: '点右下角「我要投稿」成为第一个',
                    ),
                  )
                else
                  for (var i = 0; i < _entries.length; i++)
                    _EntryCard(
                      entry: _entries[i],
                      onLike: () => _toggleLike(i),
                      onEdit: () => _submit(editing: _entries[i]),
                      onDelete: () => _delete(_entries[i]),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  final CampaignEntry entry;
  final VoidCallback onLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: AuthorHeader(
                      authorId: entry.authorId, time: entry.createdAt),
                ),
                if (entry.isMine)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
              ],
            ),
          ),
          if (entry.imageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: PageView(
                children: [
                  for (var i = 0; i < entry.imageUrls.length; i++)
                    GestureDetector(
                      onTap: () =>
                          ImageViewerPage.open(context, entry.imageUrls, i),
                      child: NetworkPhoto(entry.imageUrls[i]),
                    ),
                ],
              ),
            ),
          if (entry.caption.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(entry.caption),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 12, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    entry.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: entry.likedByMe ? Colors.redAccent : null,
                  ),
                ),
                Text('${entry.likeCount}',
                    style: TextStyle(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
