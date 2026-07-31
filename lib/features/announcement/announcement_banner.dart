import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/announcement.dart';

/// 快闪活动横幅（放于时间线顶部）。可横向滑动多条，点击跳转外部网站。
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  final _repo = AnnouncementRepository();
  late Future<List<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchActive();
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Announcement>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            height: 120,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.92),
              itemCount: items.length,
              itemBuilder: (context, i) => _BannerCard(
                item: items[i],
                onTap: () => _open(items[i].linkUrl),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item, required this.onTap});

  final Announcement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primaryContainer,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Image.network(item.imageUrl!, fit: BoxFit.cover),
              // 底部渐变，保证文字可读
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (item.linkUrl != null && item.linkUrl!.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text('查看详情',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Icon(Icons.arrow_forward,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
