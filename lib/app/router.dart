import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/campaign/campaign_list_page.dart';
import '../features/drift_bottle/welcome_drift_page.dart';
import '../features/home/home_shell.dart';
import '../features/lab/image_lab_page.dart';
import '../features/photography/photography_page.dart';
import '../features/profile/profile_page.dart';

/// 全局路由。登录后进入带底部导航的主壳（摄影 / 分析 / 我的）。
///
/// 使用 StatefulShellRoute.indexedStack：各 Tab 拥有独立的导航栈，
/// 切换 Tab 时页面状态得以保留。
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeDriftPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/photography',
              builder: (context, state) => const PhotographyPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/campaigns',
              builder: (context, state) => const CampaignListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lab',
              builder: (context, state) => const ImageLabPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
