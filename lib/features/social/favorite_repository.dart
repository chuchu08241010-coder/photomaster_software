import '../../core/supabase/supabase_client.dart';

/// 收藏仓储（通用，按 item_type 区分内容种类）。
class FavoriteRepository {
  /// 当前用户在某类内容下已收藏的 id 集合。
  Future<Set<String>> myFavoriteIds(String itemType) async {
    final uid = currentUserId;
    if (uid == null) return {};
    final rows = await supabase
        .from('favorites')
        .select('item_id')
        .eq('user_id', uid)
        .eq('item_type', itemType);
    return (rows as List).map((e) => e['item_id'] as String).toSet();
  }

  /// 收藏 / 取消收藏。
  Future<void> setFavorite({
    required String itemType,
    required String itemId,
    required bool value,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    if (value) {
      await supabase.from('favorites').upsert({
        'user_id': uid,
        'item_type': itemType,
        'item_id': itemId,
      });
    } else {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', uid)
          .eq('item_type', itemType)
          .eq('item_id', itemId);
    }
  }
}
