# حارس تشغيل محلي — يعيد إقلاع الخادم فور موته ويسجل كل دورة
# للاستخدام المحلي فقط أثناء مرحلة الاختبارات
$log = "C:\Users\DrCinco\Desktop\sand\al-fadaa-backend\backend-watchdog.log"
Set-Location "C:\Users\DrCinco\Desktop\sand\al-fadaa-backend"
while ($true) {
  Add-Content -Path $log -Value ("START " + (Get-Date -Format o))
  node dist/src/main.js *>> "C:\Users\DrCinco\Desktop\sand\al-fadaa-backend\backend-run.log"
  Add-Content -Path $log -Value ("EXIT code=" + $LASTEXITCODE + " " + (Get-Date -Format o))
  Start-Sleep -Seconds 2
}
