-- PhotoMaster Supabase 初始化脚本
-- 在 Supabase 控制台 → SQL Editor 里粘贴并 Run。
-- 另外记得在 Authentication → Sign In / Providers 里打开「Anonymous」登录。

-- ============ 表 ============

-- 用户资料（与 auth.users 关联）
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- 摄影帖（一组照片 + 文案 + 标签 + 地址）
create table if not exists public.photo_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  caption text not null default '',
  tags text[] not null default '{}',
  location text,
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists photo_posts_created_at_idx
  on public.photo_posts (created_at desc);

-- ============ 行级安全 (RLS) ============

alter table public.profiles enable row level security;
alter table public.photo_posts enable row level security;

-- profiles：登录用户都可读；只能增改自己的
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- photo_posts：登录用户都可读（小圈子）；只能发/删自己的
drop policy if exists "photo_posts_select" on public.photo_posts;
create policy "photo_posts_select" on public.photo_posts
  for select to authenticated using (true);

drop policy if exists "photo_posts_insert_own" on public.photo_posts;
create policy "photo_posts_insert_own" on public.photo_posts
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "photo_posts_delete_own" on public.photo_posts;
create policy "photo_posts_delete_own" on public.photo_posts
  for delete to authenticated using (auth.uid() = author_id);

-- ============ 存储桶（照片） ============

insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

-- 读取：登录用户可读
drop policy if exists "post_images_select" on storage.objects;
create policy "post_images_select" on storage.objects
  for select to authenticated using (bucket_id = 'post-images');

-- 上传：只能上传到以自己 uid 命名的文件夹下
drop policy if exists "post_images_insert_own" on storage.objects;
create policy "post_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 删除：只能删自己文件夹下的
drop policy if exists "post_images_delete_own" on storage.objects;
create policy "post_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============ 收藏（通用：摄影帖/文字帖/美食帖复用） ============

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_type text not null,   -- 'photo_post' | 'text_post' | 'food_post'
  item_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (user_id, item_type, item_id)
);

alter table public.favorites enable row level security;

-- 收藏：为支持「收藏数」展示，圈内登录用户可读全部；但只能增/删自己的
drop policy if exists "favorites_select_own" on public.favorites;
drop policy if exists "favorites_select" on public.favorites;
create policy "favorites_select" on public.favorites
  for select to authenticated using (true);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own" on public.favorites
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own" on public.favorites
  for delete to authenticated using (auth.uid() = user_id);

-- ============ 评论（通用） ============

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  item_type text not null,
  item_id uuid not null,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists comments_item_idx
  on public.comments (item_type, item_id, created_at);

alter table public.comments enable row level security;

-- 评论：小圈子内登录用户都可读；只能发/删自己的
drop policy if exists "comments_select" on public.comments;
create policy "comments_select" on public.comments
  for select to authenticated using (true);

drop policy if exists "comments_insert_own" on public.comments;
create policy "comments_insert_own" on public.comments
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "comments_delete_own" on public.comments;
create policy "comments_delete_own" on public.comments
  for delete to authenticated using (auth.uid() = author_id);

-- ============ 摄影帖：EXIF 拍摄参数（型号/光圈/快门/ISO/焦距） ============

alter table public.photo_posts
  add column if not exists exif jsonb;

-- 用户资料：头像（为已存在的库补列）
alter table public.profiles
  add column if not exists avatar_url text;

-- ============ 文字帖（与图片分享隔离，6 种类型） ============
-- type: equipment(器材) | tips(技巧/教程) | question(提问求助)
--       postprocess(后期参数) | preset(预设参数) | spot(机位分享)

create table if not exists public.text_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null default '',
  body text not null default '',
  location text,
  created_at timestamptz not null default now()
);

create index if not exists text_posts_created_at_idx
  on public.text_posts (created_at desc);
create index if not exists text_posts_type_idx
  on public.text_posts (type, created_at desc);

alter table public.text_posts enable row level security;

drop policy if exists "text_posts_select" on public.text_posts;
create policy "text_posts_select" on public.text_posts
  for select to authenticated using (true);

drop policy if exists "text_posts_insert_own" on public.text_posts;
create policy "text_posts_insert_own" on public.text_posts
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "text_posts_delete_own" on public.text_posts;
create policy "text_posts_delete_own" on public.text_posts
  for delete to authenticated using (auth.uid() = author_id);

-- ============ 美食帖（两社区：推荐 / 避雷） ============
-- community: recommend(推荐) | avoid(避雷)

create table if not exists public.food_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  community text not null,
  store_name text not null default '',
  body text not null default '',
  location text,
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists food_posts_created_at_idx
  on public.food_posts (created_at desc);
create index if not exists food_posts_community_idx
  on public.food_posts (community, created_at desc);

alter table public.food_posts enable row level security;

drop policy if exists "food_posts_select" on public.food_posts;
create policy "food_posts_select" on public.food_posts
  for select to authenticated using (true);

drop policy if exists "food_posts_insert_own" on public.food_posts;
create policy "food_posts_insert_own" on public.food_posts
  for insert to authenticated with check (auth.uid() = author_id);

drop policy if exists "food_posts_delete_own" on public.food_posts;
create policy "food_posts_delete_own" on public.food_posts
  for delete to authenticated using (auth.uid() = author_id);
