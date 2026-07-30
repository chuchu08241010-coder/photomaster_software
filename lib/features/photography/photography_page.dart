import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';

/// 摄影板块。
/// 两个子页：时间线（朋友圈式动态）与文字帖（独立于图片分享）。
class PhotographyPage extends StatelessWidget {
  const PhotographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('摄影'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '时间线'),
              Tab(text: '文字帖'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SectionPlaceholder(
              icon: Icons.dynamic_feed_outlined,
              title: '好友照片时间线',
              subtitle: '发一组照片，同时进主页与时间线\n可收藏 · 评论 · 发地址（不点赞）',
            ),
            SectionPlaceholder(
              icon: Icons.article_outlined,
              title: '文字帖分享',
              subtitle: '分 N 种类型的文字分享，与图片隔离\n可收藏 · 评论',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_a_photo),
        ),
      ),
    );
  }
}
