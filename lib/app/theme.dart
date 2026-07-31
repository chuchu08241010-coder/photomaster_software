import 'package:flutter/material.dart';

/// 一套配色方案：主色 / 辅色 / 点缀色（用量比例约 6:3:1）。
class AppPalette {
  const AppPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final String name;
  final Color primary; // 主色（占比 6）
  final Color secondary; // 辅色（占比 3）
  final Color accent; // 点缀色（占比 1）
}

/// 用户可在设置里选择的配色方案。
const List<AppPalette> kPalettes = [
  AppPalette(
    name: '海蓝玫瑰',
    primary: Color(0xFF144EA0),
    secondary: Color(0xFFCF98AE),
    accent: Color(0xFF131610),
  ),
  AppPalette(
    name: '雾蓝焦糖',
    primary: Color(0xFFBBC8D3),
    secondary: Color(0xFFE3C6AD),
    accent: Color(0xFFA2825E),
  ),
  AppPalette(
    name: '粉陶橄榄',
    primary: Color(0xFFEAC1C1),
    secondary: Color(0xFFBC7A3A),
    accent: Color(0xFF45543E),
  ),
  AppPalette(
    name: '金辉薄荷',
    primary: Color(0xFFFFD700),
    secondary: Color(0xFFF0F8FF),
    accent: Color(0xFF90EE90),
  ),
  AppPalette(
    name: '紫罗兰绿',
    primary: Color(0xFF704DA8),
    secondary: Color(0xFF8DC99F),
    accent: Color(0xFFC2C0E7),
  ),
  AppPalette(
    name: '湖蓝樱粉',
    primary: Color(0xFF235991),
    secondary: Color(0xFF8CC2DD),
    accent: Color(0xFFF3CEEF),
  ),
];

/// 依据亮度选择对比文字色。
Color onColorFor(Color c) =>
    c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

/// 用选定的配色方案构建全局主题。
ThemeData buildAppTheme(AppPalette p) {
  final base = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: Brightness.light,
  );
  final scheme = base.copyWith(
    primary: p.primary,
    onPrimary: onColorFor(p.primary),
    secondary: p.secondary,
    onSecondary: onColorFor(p.secondary),
    tertiary: p.accent,
    onTertiary: onColorFor(p.accent),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
  );
}
