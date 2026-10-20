// معاينة محلية للوحة بخادم وهمي في الذاكرة (لا تتصل بالإنتاج).
// flutter build web --target tool/preview_main.dart --output build/preview
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../test/support/fake_server.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final server = FakeServer();
  const names = [
    ('زيد علي الشمري', 'علي حسن الشمري', 'الرابع الابتدائي', 'شعبة أ'),
    ('محمد سجاد الربيعي', 'سجاد كريم الربيعي', 'الأول الابتدائي', 'شعبة أ'),
    ('حسن حيدر الكرخي', 'حيدر جاسم الكرخي', 'الثالث الابتدائي', 'شعبة ب'),
    ('عبدالله قاسم التميمي', 'قاسم رائد التميمي', 'الخامس الابتدائي', 'شعبة ج'),
    ('يوسف عمر الدليمي', 'عمر فاروق الدليمي', 'الثاني الابتدائي', 'شعبة أ'),
    ('مصطفى باقر الخفاجي', 'باقر ناصر الخفاجي', 'السادس الابتدائي', 'شعبة ب'),
  ];
  for (var i = 0; i < names.length; i++) {
    final id = 20 + i;
    server.students.add({
      'id': id,
      'name': names[i].$1,
      'parent_name': names[i].$2,
      'parent_phone': '+96477010000${i + 10}',
      'rfid_tag': 'RF-${8000 + i}',
      'grade': names[i].$3,
      'section': names[i].$4,
    });
    if (i != 3) server.punches[id] = ['07:${20 + i * 4} AM', null];
  }

  final store = MemoryTokenStore();
  await store.save(token: fakeToken, username: 'أ. أحمد السعدي');
  final client = ApiClient(baseUrl: 'http://preview.local', client: server.client);
  final services = AppServices(client, AdminApi(client, store), store);
  runApp(AlrhmanApp(services: services));
}
