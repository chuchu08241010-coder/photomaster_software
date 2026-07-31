/// 摄影帖数据模型，对应 Supabase 表 public.photo_posts。
class PhotoPost {
  const PhotoPost({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.tags,
    required this.location,
    required this.imageUrls,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String caption;
  final List<String> tags;
  final String? location;
  final List<String> imageUrls;
  final DateTime createdAt;

  factory PhotoPost.fromMap(Map<String, dynamic> map) {
    return PhotoPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      caption: (map['caption'] as String?) ?? '',
      tags: ((map['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      location: map['location'] as String?,
      imageUrls: ((map['image_urls'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
