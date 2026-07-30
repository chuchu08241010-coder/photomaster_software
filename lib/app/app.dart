import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class PhotoMasterApp extends StatelessWidget {
  const PhotoMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhotoMaster',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
