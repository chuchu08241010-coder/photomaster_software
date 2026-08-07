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
  // 主色用 fromSeed 推导版（保证与白底/文字的对比度，避免浅色系看不清）；
  // 辅色/点缀色采用调色板自定义。
  final scheme = base.copyWith(
    secondary: p.secondary,
    onSecondary: onColorFor(p.secondary),
    tertiary: p.accent,
    onTertiary: onColorFor(p.accent),
    surface: Colors.white,
  );

  const font = 'Inter';

  // 简约时尚：紧凑字距、清晰层级、充足留白。
  final text = ThemeData.light().textTheme.apply(fontFamily: font).copyWith(
        headlineMedium: const TextStyle(
            fontFamily: font,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5),
        titleLarge: const TextStyle(
            fontFamily: font,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3),
        titleMedium: const TextStyle(
            fontFamily: font,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2),
        bodyLarge: const TextStyle(fontFamily: font, height: 1.4),
        bodyMedium: const TextStyle(fontFamily: font, height: 1.4),
        bodySmall: const TextStyle(fontFamily: font, height: 1.3),
        labelLarge: const TextStyle(
            fontFamily: font, fontWeight: FontWeight.w600),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: font,
    textTheme: text,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide.none,
      labelStyle: TextStyle(
          fontFamily: font, fontSize: 12, color: scheme.onSurfaceVariant),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontFamily: font, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
            fontFamily: font, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(
          fontFamily: font, fontWeight: FontWeight.w600, fontSize: 15),
      unselectedLabelStyle:
          const TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 0.5,
      space: 1,
    ),
  );
}
