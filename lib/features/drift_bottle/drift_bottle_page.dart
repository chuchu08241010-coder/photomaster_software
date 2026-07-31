import 'package:flutter/material.dart';

import '../profile/data/profile.dart';
import 'create_drift_bottle_page.dart';
import 'data/drift_bottle.dart';

/// 漂流瓶页：随机捞一个（图铺底、文字居中、显示昵称），可换一个或扔一个。
class DriftBottlePage extends StatefulWidget {
  const DriftBottlePage({super.key});

  @override
  State<DriftBottlePage> createState() => _DriftBottlePageState();
}

class _DriftBottlePageState extends State<DriftBottlePage> {
  final _repo = DriftBottleRepository();
  late Future<DriftBottle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.random();
  }

  void _drawAnother() {
    setState(() => _future = _repo.random());
  }

  Future<void> _throwBottle() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateDriftBottlePage()),
    );
    if (created == true) _drawAnother();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('漂流瓶')),
      body: FutureBuilder<DriftBottle?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bottle = snapshot.data;
          if (bottle == null) {
            return _EmptyBottle(onThrow: _throwBottle);
          }
          return _BottleView(bottle: bottle);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _drawAnother,
        icon: const Icon(Icons.waves),
        label: const Text('再捞一个'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: OutlinedButton.icon(
            onPressed: _throwBottle,
            icon: const Icon(Icons.send_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('扔一个漂流瓶'),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBottle extends StatelessWidget {
  const _EmptyBottle({required this.onThrow});
  final VoidCallback onThrow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('海里还没有漂流瓶'),
          const SizedBox(height: 8),
          FilledButton(onPressed: onThrow, child: const Text('扔第一个')),
        ],
      ),
    );
  }
}

class _BottleView extends StatelessWidget {
  const _BottleView({required this.bottle});
  final DriftBottle bottle;

  @override
  Widget build(BuildContext context) {
    final hasImage = bottle.imageUrl != null && bottle.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 图片铺底
        if (hasImage)
          Image.network(bottle.imageUrl!, fit: BoxFit.cover)
        else
          Container(color: Theme.of(context).colorScheme.primaryContainer),
        // 压暗以突出文字
        Container(color: Colors.black.withValues(alpha: hasImage ? 0.35 : 0.0)),
        // 文字居中
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              bottle.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: hasImage
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        // 底部昵称
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: FutureBuilder<Profile?>(
              future: ProfileCache.get(bottle.authorId),
              builder: (context, snapshot) {
                final name = snapshot.data?.name ?? '匿名用户';
                return Text(
                  '—— $name',
                  style: TextStyle(
                    color: hasImage
                        ? Colors.white70
                        : Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.8),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
