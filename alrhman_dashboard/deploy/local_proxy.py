"""تشغيل نسخة الويب محلياً مع تمرير /api إلى الخادم (نفس فكرة الاستضافة).

الخادم لا يدعم CORS، لذا يجب أن يأتي الموقع والـ API من النطاق نفسه:
هذا السكربت يقدّم ملفات build/web ويمرّر أي طلب /api/* أو /health إلى الخادم.

    flutter build web --dart-define=API_BASE_URL=
    python deploy/local_proxy.py            # ثم افتح http://localhost:8800
"""
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

API = os.environ.get("API_UPSTREAM", "https://futurekids-staging.up.railway.app")
PORT = int(os.environ.get("PORT", "8800"))
WEB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")

mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("text/javascript", ".mjs")

FORWARD_REQ = ("Authorization", "Content-Type", "Accept", "If-None-Match")
FORWARD_RES = ("Content-Type", "Content-Disposition", "Retry-After", "Allow", "ETag", "Cache-Control")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=WEB, **kw)

    def _is_api(self):
        return self.path.startswith("/api/") or self.path == "/health"

    def _proxy(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        req = urllib.request.Request(API + self.path, data=body, method=self.command)
        for h in FORWARD_REQ:
            if self.headers.get(h):
                req.add_header(h, self.headers[h])
        try:
            resp = urllib.request.urlopen(req, timeout=40)
            status, headers, data = resp.status, resp.headers, resp.read()
        except urllib.error.HTTPError as e:  # 4xx/5xx تمرَّر كما هي
            status, headers, data = e.code, e.headers, e.read()
        except Exception as e:  # الخادم غير متاح
            status, headers, data = 502, {}, str(e).encode()
        self.send_response(status)
        for h in FORWARD_RES:
            if headers.get(h):
                self.send_header(h, headers[h])
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self._is_api():
            return self._proxy()
        # تطبيق صفحة واحدة: أي مسار غير موجود يعود إلى index.html
        path = self.translate_path(self.path.split("?")[0])
        if not os.path.exists(path):
            self.path = "/index.html"
        return super().do_GET()

    def do_POST(self):
        return self._proxy() if self._is_api() else self.send_error(405)

    do_PUT = do_POST
    do_DELETE = do_POST


if __name__ == "__main__":
    if not os.path.isdir(WEB):
        sys.exit("build/web غير موجود: شغّل flutter build web --dart-define=API_BASE_URL= أولاً")
    print(f"http://localhost:{PORT}  ->  /api => {API}")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
