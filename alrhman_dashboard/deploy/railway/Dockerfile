# لوحة الإدارة (Flutter Web) على Railway.
# nginx يقدّم الموقع المبني مسبقاً ويمرّر /api إلى الباك اند من نفس النطاق
# (الباك اند لا يدعم CORS، فلا يمكن للمتصفح طلبه مباشرة من نطاق آخر).
FROM nginx:1.27-alpine

# Railway يمرّر PORT؛ API_UPSTREAM عنوان الباك اند (يُغيَّر من متغيرات الخدمة).
ENV PORT=8080 \
    API_UPSTREAM=https://futurekids-staging.up.railway.app \
    API_HOST=futurekids-staging.up.railway.app

# صورة nginx الرسمية تطبّق envsubst على كل ملف في templates عند التشغيل.
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY site/ /usr/share/nginx/html/

EXPOSE 8080
