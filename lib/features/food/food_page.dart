import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import 'create_food_post_page.dart';
import 'food_community_list.dart';
import 'search_food_page.dart';

/// 美食板块。两个社区：推荐 与 避雷。
class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _recommendKey = GlobalKey<FoodCommunityListState>();
  final _avoidKey = GlobalKey<FoodCommunityListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _guardOnline() {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前为离线骨架模式，未连接云端，暂不能发帖')),
      );
      return false;
    }
    return true;
  }

  Future<void> _openCreate() async {
    if (!_guardOnline()) return;
    final community = _tabController.index == 0 ? 'recommend' : 'avoid';
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateFoodPostPage(initialCommunity: community),
      ),
    );
    if (created == true) {
      _recommendKey.currentState?.reload();
      _avoidKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('美食'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              if (!_guardOnline()) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchFoodPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '避雷'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FoodCommunityList(key: _recommendKey, community: 'recommend'),
          FoodCommunityList(key: _avoidKey, community: 'avoid'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: '发美食帖',
        child: const Icon(Icons.edit),
      ),
    );
  }
}
