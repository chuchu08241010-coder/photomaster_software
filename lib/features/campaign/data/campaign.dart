import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/storage_upload.dart';
import '../../../core/supabase/supabase_client.dart';

/// 主题投稿活动，对应 public.campaigns。
class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.rules,
    required this.createdBy,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? posterUrl;
  final String rules;
  final String? createdBy;
  final bool active;
  final DateTime createdAt;

  factory Campaign.fromMap(Map<String, dynamic> m) => Campaign(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        posterUrl: m['poster_url'] as String?,
        rules: (m['rules'] as String?) ?? '',
        createdBy: m['created_by'] as String?,
        active: (m['active'] as bool?) ?? true,
        createdAt:
            DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// 一条投稿，对应 public.campaign_entries（附带点赞聚合）。
class CampaignEntry {
  const CampaignEntry({
    required this.id,
    required this.campaignId,
    required this.authorId,
    required this.imageUrls,
    required this.caption,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
  });

  final String id;
  final String campaignId;
  final String authorId;
  final List<String> imageUrls;
  final String caption;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  bool get isMine => authorId == currentUserId;

  CampaignEntry copyWith({int? likeCount, bool? likedByMe}) => CampaignEntry(
        id: id,
        campaignId: campaignId,
        authorId: authorId,
        imageUrls: imageUrls,
        caption: caption,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  factory CampaignEntry.fromMap(
    Map<String, dynamic> m, {
    required int likeCount,
    required bool likedByMe,
  }) =>
      CampaignEntry(
        id: m['id'] as String,
        campaignId: m['campaign_id'] as String,
        authorId: m['author_id'] as String,
        imageUrls: ((m['image_urls'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        caption: (m['caption'] as String?) ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
        likeCount: likeCount,
        likedByMe: likedByMe,
      );
}

class CampaignRepository {
  /// 活动列表：进行中的在前，按创建时间倒序。
  Future<List<Campaign>> fetchCampaigns() async {
    final res = await supabase
        .from('campaigns')
        .select()
        .order('active', ascending: false)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Campaign.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 某活动下所有投稿，带点赞数与我是否已赞。
  Future<List<CampaignEntry>> fetchEntries(String campaignId) async {
    final rows = await supabase
        .from('campaign_entries')
        .select()
        .eq('campaign_id', campaignId)
        .order('created_at', ascending: false);
    final entries = (rows as List).cast<Map<String, dynamic>>();
    if (entries.isEmpty) return [];

    final ids = entries.map((e) => e['id'] as String).toList();
    final likes = await supabase
        .from('campaign_entry_likes')
        .select('entry_id, user_id')
        .inFilter('entry_id', ids);
    final uid = currentUserId;
    final counts = <String, int>{};
    final mine = <String>{};
    for (final l in (likes as List).cast<Map<String, dynamic>>()) {
      final eid = l['entry_id'] as String;
      counts[eid] = (counts[eid] ?? 0) + 1;
      if (l['user_id'] == uid) mine.add(eid);
    }
    return entries
        .map((e) => CampaignEntry.fromMap(
              e,
              likeCount: counts[e['id']] ?? 0,
              likedByMe: mine.contains(e['id']),
            ))
        .toList();
  }

  /// 发起一个新活动。
  Future<Campaign> createCampaign({
    required String title,
    required String rules,
    XFile? poster,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    String? posterUrl;
    if (poster != null) {
      posterUrl = await uploadImage(poster, prefix: 'poster');
    }
    final inserted = await supabase
        .from('campaigns')
        .insert({
          'title': title,
          'rules': rules,
          'poster_url': posterUrl,
          'created_by': uid,
        })
        .select()
        .single();
    return Campaign.fromMap(inserted);
  }

  /// 投稿（上传图片 + 文案）。
  Future<void> createEntry({
    required String campaignId,
    required List<XFile> images,
    required String caption,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    final urls = <String>[];
    for (final img in images) {
      urls.add(await uploadImage(img, prefix: 'entry'));
    }
    await supabase.from('campaign_entries').insert({
      'campaign_id': campaignId,
      'author_id': uid,
      'image_urls': urls,
      'caption': caption,
    });
  }

  /// 修改自己的投稿。keepUrls 是保留的原图，newImages 是新增的图。
  Future<void> updateEntry({
    required String entryId,
    required List<String> keepUrls,
    required List<XFile> newImages,
    required String caption,
  }) async {
    final urls = [...keepUrls];
    for (final img in newImages) {
      urls.add(await uploadImage(img, prefix: 'entry'));
    }
    await supabase.from('campaign_entries').update({
      'image_urls': urls,
      'caption': caption,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', entryId);
  }

  Future<void> deleteEntry(String entryId) async {
    await supabase.from('campaign_entries').delete().eq('id', entryId);
  }

  /// 点赞 / 取消点赞，返回操作后的状态。
  Future<bool> toggleLike(String entryId, {required bool currentlyLiked}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    if (currentlyLiked) {
      await supabase
          .from('campaign_entry_likes')
          .delete()
          .eq('entry_id', entryId)
          .eq('user_id', uid);
      return false;
    } else {
      await supabase.from('campaign_entry_likes').insert({
        'entry_id': entryId,
        'user_id': uid,
      });
      return true;
    }
  }
}
