#!/bin/bash
# تشغيل وضع الإنتاج — بدون بيانات تجريبية
flutter run -d chrome \
  --dart-define=API_URL=https://api.al-fadaa.com/api/v1 \
  --dart-define=DEV_MODE=false
