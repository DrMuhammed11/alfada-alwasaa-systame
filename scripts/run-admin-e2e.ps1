# ==============================================================================
#  تشغيل وتثبيت واختبار تطبيق الأدمن على هذا الجهاز — سكربت واحد شامل
#  الاستخدام (PowerShell):
#    cd C:\Users\DrCinco\Desktop\مراسلات
#    powershell -ExecutionPolicy Bypass -File scripts\run-admin-e2e.ps1
#  خيارات:
#    -AutoLogin          يكتب بيانات الدخول تلقائياً في التطبيق ويصوّر اللوحة الرئيسية
#    -SeedPassword "X"   يثبت كلمة مرور الحسابات التجريبية (وإلا تُولَّد وتُطبع)
# ==============================================================================
param(
    [switch]$AutoLogin,
    [string]$SeedPassword = ""
)

$ErrorActionPreference = "Continue"
$root    = "C:\Users\DrCinco\Desktop\مراسلات"
$backend = Join-Path $root "al-fadaa-backend"
$admin   = Join-Path $root "al_fadaa_admin"
$shots   = Join-Path $root "screenshots"
New-Item -ItemType Directory -Force -Path $shots | Out-Null

function Step($msg)  { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "  ! $msg" -ForegroundColor Yellow }

# ─── 1) قاعدة البيانات (Docker) ───────────────────────────────────────────────
Step "1/7 قاعدة البيانات Postgres عبر Docker"
$dockerOk = $false
try {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { $dockerOk = $true }
} catch {}
if ($dockerOk) {
    Push-Location $backend
    docker compose up -d db
    Start-Sleep -Seconds 6
    Pop-Location
    Ok "قاعدة البيانات تعمل على localhost:5432"
} else {
    Warn "Docker غير متاح — إن كانت Postgres تعمل محلياً فتابع، وإلا سيفشل الخادم"
}

# ─── 2) الترحيلات والبذرة ─────────────────────────────────────────────────────
Step "2/7 الترحيلات والبذرة"
Push-Location $backend
npx prisma migrate deploy
if ($SeedPassword -ne "") {
    $env:SEED_PASSWORD = $SeedPassword
}
npx prisma db seed
Pop-Location
Ok "قاعدة البيانات جاهزة — كلمة مرور الحسابات التجريبية مطبوعة أعلاه"

# ─── 3) تشغيل الخادم الخلفي ───────────────────────────────────────────────────
Step "3/7 تشغيل الخادم الخلفي على المنفذ 3000"
Push-Location $backend
if (-not (Test-Path "dist\main.js")) { npm run build }
Start-Process -FilePath "node" -ArgumentList "dist\main.js" -WorkingDirectory $backend -WindowStyle Minimized
Pop-Location

$backendUp = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 2
    try {
        $h = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -TimeoutSec 3
        if ($h.status -in @("ok", "warning")) { $backendUp = $true; break }
    } catch {}
}
if ($backendUp) { Ok "الخادم يعمل ويستجيب (/health)" }
else { Warn "الخادم لم يستجب — تابع لفحص الواجهة فقط، وراجع نافذة الخادم" }

# ─── 4) فحص واختبار تطبيق الأدمن ─────────────────────────────────────────────
Step "4/7 flutter analyze + flutter test (تطبيق الأدمن)"
Push-Location $admin
flutter pub get
flutter analyze
if ($LASTEXITCODE -ne 0) { Warn "analyze أعاد ملاحظات — راجعها" } else { Ok "التحليل الثابت نظيف" }
flutter test
if ($LASTEXITCODE -eq 0) { Ok "الاختبارات ناجحة" } else { Warn "اختبار فاشل — راجع المخرجات" }

# ─── 5) بناء نسخة ويندوز Release ─────────────────────────────────────────────
Step "5/7 بناء تطبيق الأدمن لويندوز (Release)"
flutter build windows --release
if ($LASTEXITCODE -eq 0) { Ok "تم البناء" } else { throw "فشل البناء — راجع المخرجات" }
Pop-Location

$exe = Join-Path $admin "build\windows\x64\runner\Release\al_fadaa_admin.exe"
if (-not (Test-Path $exe)) { throw "لم يُعثر على الملف التنفيذي: $exe" }

# ─── 6) الإطلاق ولقطة شاشة الدخول ────────────────────────────────────────────
Step "6/7 إطلاق التطبيق ولقطة شاشة"
Start-Process -FilePath $exe
Start-Sleep -Seconds 10

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
function Save-Screen($path) {
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "  📸 لقطة محفوظة: $path"
}

$loginShot = Join-Path $shots "admin_login.png"
Save-Screen $loginShot

# ─── 7) دخول حقيقي اختياري + لقطة اللوحة ─────────────────────────────────────
if ($AutoLogin) {
    Step "7/7 دخول حقيقي عبر لوحة المفاتيح"
    $email = Read-Host "أدخل بريد الأدمن (مثال: admin@al-fadaa.com)"
    $pass  = Read-Host "أدخل كلمة المرور (المطبوعة من البذرة)"
    # التركيز على نافذة التطبيق ثم الكتابة: البريد TAB كلمة المرور ENTER
    $wshell = New-Object -ComObject wscript.shell
    $wshell.AppActivate("al_fadaa_admin") | Out-Null
    Start-Sleep -Seconds 1
    $wshell.SendKeys($email)
    $wshell.SendKeys("{TAB}")
    Start-Sleep -Milliseconds 300
    $wshell.SendKeys($pass)
    Start-Sleep -Milliseconds 300
    $wshell.SendKeys("{ENTER}")
    Start-Sleep -Seconds 8
    Save-Screen (Join-Path $shots "admin_dashboard.png")
    Write-Host "  راجع اللقطة الثانية: إن ظهرت لوحة الإحصائيات فالدخول ناجح 100%"
} else {
    Write-Host "`n  سجّل الدخول يدوياً في نافذة التطبيق ثم شغّل لقطة ثانية، أو أعد السكربت مع -AutoLogin"
}

Write-Host "`n✅ اكتمل التثبيت والتشغيل — اللقطات في: $shots" -ForegroundColor Green
