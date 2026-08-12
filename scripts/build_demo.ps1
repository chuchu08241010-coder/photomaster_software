# 构建「网友体验版(demo)」网页 —— 连的是独立的 demo Supabase，不碰你的私有圈子。
# 用法：在项目根目录 PowerShell 里运行  ./scripts/build_demo.ps1
# 产物在 netlify_demo/（已 gitignore），把它整个文件夹拖到一个「新的」Netlify 站点即可。

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path "env/supabase.demo.json")) {
  Write-Host "缺少 env/supabase.demo.json" -ForegroundColor Red
  Write-Host "请先复制模板并填入你的 demo Supabase 凭据：" -ForegroundColor Yellow
  Write-Host "  Copy-Item env/supabase.demo.json.example env/supabase.demo.json"
  exit 1
}

$env:JAVA_HOME = "E:\Java\jdk-17.0.20+8"
$env:PUB_CACHE = "E:\PubCache"
$env:PATH = "E:\huangdianyi\flutter\bin;$env:JAVA_HOME\bin;$env:PATH"

Write-Host "==> 构建 demo web ..." -ForegroundColor Cyan
flutter build web --release --no-web-resources-cdn --dart-define=DEMO=true --dart-define-from-file=env/supabase.demo.json

Write-Host "==> 同步到 netlify_demo/ ..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force netlify_demo | Out-Null
Copy-Item -Path build\web\* -Destination netlify_demo -Recurse -Force

# SPA 路由回退 + 关键文件不被长期缓存
"/*    /index.html   200" | Set-Content -Encoding UTF8 netlify_demo\_redirects
@"
/index.html
  Cache-Control: no-cache
/flutter_bootstrap.js
  Cache-Control: no-cache
/flutter_service_worker.js
  Cache-Control: no-cache
"@ | Set-Content -Encoding UTF8 netlify_demo\_headers

Write-Host "==> 完成！把 netlify_demo 文件夹拖到一个新的 Netlify 站点即可。" -ForegroundColor Green
