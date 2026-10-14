# بناء نسخة الويب للنشر (الـ API من نفس النطاق عبر الوكيل)
flutter build web --dart-define=API_BASE_URL= --no-wasm-dry-run
Copy-Item deploy/_redirects, deploy/vercel.json build/web/
Write-Host "جاهز: ارفع مجلد build/web"
