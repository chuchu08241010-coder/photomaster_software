import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/storage_upload.dart';
import '../../../core/supabase/supabase_client.dart';

/// 用户资料模型，对应 public.profiles。
class Profile {
  const Profile(
      {required this.id, this.displayName, this.avatarUrl, this.ipLocation});

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? ipLocation;

  String get name =>
      (displayName == null || displayName!.trim().isEmpty)
          ? '匿名用户'
          : displayName!.trim();

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        ipLocation: map['ip_location'] as String?,
      );
}

class ProfileRepository {
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

  Future<Profile> upsert(
      {String? displayName, String? avatarUrl, String? ipLocation}) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('未登录');
    final data = <String, dynamic>{
      'id': uid,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (ipLocation != null) 'ip_location': ipLocation,
    };
    final row =
        await supabase.from('profiles').upsert(data).select().single();
    ProfileCache.invalidate(uid);
    return Profile.fromMap(row);
  }

  Future<String> uploadAvatar(XFile file) async {
    return uploadImage(file, prefix: 'avatar');
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
