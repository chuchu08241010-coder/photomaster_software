# 发版检查清单（Release Checklist）

每次发新版照着做即可。命令都在项目根目录 `E:\huangdianyi\PhotoMaster` 执行。

> 每个新终端先设置一次环境变量（PATH / JAVA_HOME / Android / 缓存目录）：
> ```powershell
> $env:JAVA_HOME="E:\Java\jdk-17.0.20+8"; $env:ANDROID_SDK_ROOT="E:\Android\Sdk"; $env:ANDROID_HOME="E:\Android\Sdk"; $env:GRADLE_USER_HOME="E:\gradle"; $env:PUB_CACHE="E:\PubCache"; $env:PATH="E:\huangdianyi\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_SDK_ROOT\platform-tools;$env:PATH"
> ```

## 1. 改版本号
编辑 `pubspec.yaml` 的 `version: 1.0.X+N`（`+N` 是 build 号，每次都要比上次大）。

## 2. 自检
```powershell
flutter analyze
```
无 error 再继续（info 级提示可忽略）。

## 3. 构建 Web + 同步部署目录
```powershell
flutter build web --release --no-web-resources-cdn --dart-define-from-file=env/supabase.json
Copy-Item -Path build\web\* -Destination netlify_site -Recurse -Force
```
> `--no-web-resources-cdn` 避免中国网络下 CanvasKit 从 Google CDN 加载导致白屏。

## 4. 构建 APK + 同步到分发目录
```powershell
flutter build apk --release --dart-define-from-file=env/supabase.json
Copy-Item build\app\outputs\flutter-apk\app-release.apk apk_dist\PhotoMaster.apk -Force
```
> 若报 `mergeReleaseNativeLibs ... not a regular file`，先 `flutter clean` 再重建。

## 5. 提交 + 打 tag + 推送
```powershell
git add -A
git commit -m "feat: 本次更新说明"
git push
git tag -a v1.0.X -m "PhotoMaster v1.0.X：更新说明"
git push origin v1.0.X
```

## 6. 发 GitHub Release 并挂 APK
在 GitHub 仓库 → Releases → Draft a new release：选 tag `v1.0.X` → 填标题/说明 → 拖入 `apk_dist\PhotoMaster.apk` → Publish。
下载直链会是：
`https://github.com/chuchu08241010-coder/photomaster_software/releases/download/v1.0.X/PhotoMaster.apk`

## 7. 部署
- **网页**：把 `netlify_site` 拖到 Netlify 网页站点。
- **安装包**：把 `apk_dist` 拖到 Netlify 的 APK 站点（或直接用上面的 GitHub Release 直链）。

## 8. Supabase（按需）

### 8a. 更新“应用内更新提示”（每次发版都做）
在 SQL Editor 执行（`version_code` 要和 `pubspec.yaml` 的 `+N` 一致）：
```sql
insert into public.app_release(id, version_code, version_name, notes, url)
values (1, N, '1.0.X', '本次更新说明',
  'https://github.com/chuchu08241010-coder/photomaster_software/releases/download/v1.0.X/PhotoMaster.apk')
on conflict (id) do update set
  version_code = excluded.version_code,
  version_name = excluded.version_name,
  notes        = excluded.notes,
  url          = excluded.url,
  updated_at   = now();
```

### 8b. 改了数据库结构时（仅当本次动了 schema.sql）
在 SQL Editor **重跑整份** `supabase/schema.sql`（幂等，安全）。

---

## 备忘
- 装过旧版的朋友，签名或大改后需**先卸载再装**。
- 凭据 `env/supabase.json` 只在本地、不进 git；开源用户需自建 Supabase（见 README）。
