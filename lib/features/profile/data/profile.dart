import 'dart:io';

import '../../../core/supabase/supabase_client.dart';

/// 用户资料模型，对应 public.profiles。
class Profile {
  const Profile({required this.id, this.displayName, this.avatarUrl});

  final String id;
  final String? displayName;
  final String? avatarUrl;

  String get name =>
      (displayName == null || displayName!.trim().isEmpty)
          ? '匿名用户'
          : displayName!.trim();

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        avatarUrl: map['avatar_url'] as String?,
      );
}

class ProfileRepository {
  static const String _bucket = 'post-images';

  Future<Profile?> getById(String id) async {
    final rows =
        await supabase.from('profiles').select().eq('id', id).limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return Profile.fromMap(list.first as Map<String, dynamic>);
  }

  Future<Profile?> getMine() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getById(uid);
  }

  Future<Profile> upsert({String? displayName, String? avatarUrl}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    final data = <String, dynamic>{
      'id': uid,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    final row =
        await supabase.from('profiles').upsert(data).select().single();
    ProfileCache.invalidate(uid);
    return Profile.fromMap(row);
  }

  Future<String> uploadAvatar(File file) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    final dot = file.path.lastIndexOf('.');
    final ext = dot >= 0 ? file.path.substring(dot) : '.jpg';
    final objectPath = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
    await supabase.storage.from(_bucket).upload(objectPath, file);
    return supabase.storage.from(_bucket).getPublicUrl(objectPath);
  }
}

/// 简单的进程内缓存，避免同一作者被重复查询。
class ProfileCache {
  ProfileCache._();
  static final ProfileRepository _repo = ProfileRepository();
  static final Map<String, Future<Profile?>> _cache = {};

  static Future<Profile?> get(String id) =>
      _cache.putIfAbsent(id, () => _repo.getById(id));

  static void invalidate(String id) => _cache.remove(id);
}
