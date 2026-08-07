import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_config.dart';
import '../profile/data/profile.dart';
import 'data/drift_bottle.dart';

/// 每日首幕：打开 App 时先展示一条随机漂流瓶（图铺底、宋体文字居中），
/// 点按/上滑进入主界面。每天只展示一次。
class WelcomeDriftPage extends StatefulWidget {
  const WelcomeDriftPage({super.key});

  static const _dateKey = 'welcome_bottle_date';

  /// 今天是否还没展示过开场。未配置云端时永远不展示。
  static Future<bool> shouldShow() async {
    if (!SupabaseConfig.isConfigured) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateKey) != _today();
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _today());
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  @override
  State<WelcomeDriftPage> createState() => _WelcomeDriftPageState();
}

class _WelcomeDriftPageState extends State<WelcomeDriftPage>
    with SingleTickerProviderStateMixin {
  final _repo = DriftBottleRepository();
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    WelcomeDriftPage.markShown();
    _init();
  }

  DriftBottle? _bottle;
  bool _loading = true;

  Future<void> _init() async {
    DriftBottle? bottle;
    try {
      bottle = await _repo.random();
    } catch (_) {
      bottle = null;
    }
    if (!mounted) return;
    // 海里没瓶子就不打扰，直接进主界面。
    if (bottle == null) {
      _enter();
      return;
    }
    setState(() {
      _bottle = bottle;
      _loading = false;
    });
  }

  void _enter() {
    if (!mounted) return;
    context.go('/photography');
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white24),
        ),
      );
    }
    final bottle = _bottle!;
    final hasImage = bottle.imageUrl != null && bottle.imageUrl!.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _enter,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -100) _enter();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(bottle.imageUrl!, fit: BoxFit.cover)
            else
              Container(color: const Color(0xFF11151A)),
            // 上下暗角，突出文字
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.black26,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            FadeTransition(
              opacity: _fade,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日漂流',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 15,
                          letterSpacing: 6,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        bottle.body,
                        style: const TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 26,
                          height: 1.7,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<Profile?>(
                        future: ProfileCache.get(bottle.authorId),
                        builder: (context, snap) {
                          final name = snap.data?.name ?? '匿名漂流者';
                          return Text(
                            '—— $name',
                            style: TextStyle(
                              fontFamily: 'Serif',
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.keyboard_arrow_up_rounded,
                                color: Colors.white.withValues(alpha: 0.6)),
                            Text(
                              '轻触进入',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.6),
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
          ],
        ),
      ),
    );
  }
}
