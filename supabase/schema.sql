-- PhotoMaster Supabase 初始化脚本
-- 在 Supabase 控制台 → SQL Editor 里粘贴并 Run。
-- 另外记得在 Authentication → Sign In / Providers 里打开「Anonymous」登录。

-- ============ 表 ============

-- 用户资料（与 auth.users 关联）
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
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
