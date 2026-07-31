import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import 'theme_controller.dart';

class PhotoMasterApp extends ConsumerWidget {
  const PhotoMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index =
        ref.watch(themeControllerProvider).clamp(0, kPalettes.length - 1);
    return MaterialApp.router(
      title: 'PhotoMaster',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(kPalettes[index]),
      routerConfig: appRouter,
    );
  }
}
