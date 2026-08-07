import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/network_photo.dart';
import '../../core/widgets/section_placeholder.dart';
import 'campaign_detail_page.dart';
import 'create_campaign_page.dart';
import 'data/campaign.dart';

/// 主题投稿活动列表：像公众号推送——1:1 海报 + 一行标题，点进去看规则并投稿。
class CampaignListPage extends StatefulWidget {
  const CampaignListPage({super.key});

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage> {
  final _repo = CampaignRepository();
  late Future<List<Campaign>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Campaign>> _load() async {
    if (!SupabaseConfig.isConfigured) return [];
    return _repo.fetchCampaigns();
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _openDetail(Campaign c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CampaignDetailPage(campaign: c)),
    );
    _refresh();
  }

  Future<void> _create() async {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前为离线骨架模式，暂不能发起活动')),
      );
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCampaignPage()),
    );
    if (ok == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主题活动')),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: '发起活动',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Campaign>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return SectionPlaceholder(
              icon: Icons.error_outline,
              title: '加载失败',
              subtitle: '${snap.error}',
            );
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return const SectionPlaceholder(
              icon: Icons.campaign_outlined,
              title: '还没有主题活动',
              subtitle: '点右下角 + 发起第一个投稿活动',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: list.length,
              itemBuilder: (context, i) => _CampaignCover(
                campaign: list[i],
                onTap: () => _openDetail(list[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CampaignCover extends StatelessWidget {
  const _CampaignCover({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPoster =
        campaign.posterUrl != null && campaign.posterUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPoster)
                  NetworkPhoto(campaign.posterUrl!)
                else
                  Container(color: const Color(0xFF20262E)),
                // 底部渐变压暗，突出标题
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!campaign.active)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('已结束',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: serifDisplay(
                          size: 24,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
