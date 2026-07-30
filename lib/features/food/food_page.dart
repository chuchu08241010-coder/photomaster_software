import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';

/// 美食板块。
/// 两个社区：推荐 与 避雷。
class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('美食'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '推荐'),
              Tab(text: '避雷'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SectionPlaceholder(
              icon: Icons.thumb_up_alt_outlined,
              title: '美食推荐',
              subtitle: '分享好吃的 · 可发地址 · 关键词智能搜索',
            ),
            SectionPlaceholder(
              icon: Icons.warning_amber_outlined,
              title: '美食避雷',
              subtitle: '踩雷提醒 · 可发地址 · 关键词智能搜索',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
