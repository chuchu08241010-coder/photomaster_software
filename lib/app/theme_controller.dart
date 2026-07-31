import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 保存/读取用户选择的配色方案索引。
class ThemeController extends Notifier<int> {
  static const String _key = 'palette_index';

  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index >= 0) state = index;
  }

  Future<void> select(int index) async {
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, int>(ThemeController.new);
