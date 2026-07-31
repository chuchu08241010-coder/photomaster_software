import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/theme_controller.dart';

/// 设置页：目前包含配色方案选择。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(themeControllerProvider).clamp(0, kPalettes.length - 1);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('配色方案', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (var i = 0; i < kPalettes.length; i++)
            _PaletteTile(
              palette: kPalettes[i],
              selected: i == selected,
              onTap: () => ref.read(themeControllerProvider.notifier).select(i),
            ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '色条比例为 主色 : 辅色 : 点缀色 = 6 : 3 : 1',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(palette.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                Expanded(flex: 6, child: ColoredBox(color: palette.primary)),
                Expanded(flex: 3, child: ColoredBox(color: palette.secondary)),
                Expanded(flex: 1, child: ColoredBox(color: palette.accent)),
              ],
            ),
          ),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
    );
  }
}
