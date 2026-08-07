import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 使用说明书：离线静态内容，介绍各功能怎么用。
class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  static const _sections = <(String, String)>[
    (
      '这是什么',
      'PhotoMaster 是一个小圈子的摄影分享与影像分析工具。所有内容都由圈内好友上传，'
          '非必要不联网、尽量少占手机内存。',
    ),
    (
      '摄影 · 时间线',
      '点右下角「+」发一组照片，可写文案、加 #标签、选拍摄地址。发布后进入朋友圈式时间线'
          '与你的个人主页。图片会自动压缩上传、本地缓存，点开可全屏查看与缩放。\n'
          '拍摄参数（型号/光圈/快门/ISO/焦距）会在本地从照片 EXIF 自动读取。',
    ),
    (
      '摄影 · 文字帖',
      '切到「文字帖」子页，可发器材分享、拍摄技巧、提问求助、后期/预设参数、机位分享等。'
          '与图片分享相互独立，同样可收藏、评论。',
    ),
    (
      '编辑与删除',
      '自己的帖子在卡片右下角「⋯」里可以「编辑」或「删除」。编辑时能增删图片、改文案、'
          '改标签与地址。',
    ),
    (
      '收藏与评论',
      '每条帖子底部可收藏（书签）与评论。有人评论你的帖子时，摄影页右上角的铃铛会出现红点提醒，'
          '点进去可查看「消息」。',
    ),
    (
      '主题活动 · 投稿',
      '「活动」页像公众号推送：一张海报配一行标题。点进去看活动规则，点「我要投稿」上传作品。'
          '投稿后可随时编辑或删除自己的作品，其他人可以给你点赞。你也能点右下角「+」发起新活动。',
    ),
    (
      '分析',
      '「分析」页可选一张照片做本地画质分析：质量评分、亮度/RGB 直方图、波形图，以及完整 EXIF。'
          '全程在手机本地完成，不上传。',
    ),
    (
      '漂流瓶',
      '每天第一次打开 App 会先展示一条随机漂流瓶（整屏图配文字），轻触或上滑进入主界面。'
          '也可在「我的 → 漂流瓶」里再捞或扔一个。',
    ),
    (
      '其他',
      '「我的」页可编辑昵称头像、切换配色方案、查看 IP 属地。有新版本时启动会自动提示更新。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('使用说明')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('使用说明书', style: serifDisplay(size: 30)),
          const SizedBox(height: 8),
          Text('几分钟了解圈子里能玩什么。',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 24),
          for (final s in _sections) ...[
            Text(s.$1, style: serifDisplay(size: 20)),
            const SizedBox(height: 8),
            Text(s.$2,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
