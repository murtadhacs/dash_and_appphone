import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/activity_log.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/ui/ui_table.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _items = <ActivityLogItem>[];
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss', 'en');
  bool _started = false, _loading = false, _loaded = false, _hasMore = false;
  int? _before;
  String? _error;
  bool _failedMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading || (more && (!_hasMore || _before == null))) return;
    setState(() {
      _loading = true;
      _error = null;
      _failedMore = more;
    });
    try {
      final page = await AppScope.of(
        context,
      ).api.activityLog(before: more ? _before : null);
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(page.items.where((item) => ids.add(item.id)));
        // Preserve the server's descending order and cursor, even with id gaps.
        _before = page.nextBefore;
        _hasMore = page.hasMore && _before != null;
        _loaded = true;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _result(ActivityLogItem item) {
    final (label, tone) = switch (item.result) {
      'success' => ('نجاح', BadgeTone.ok),
      'rejected' => ('مرفوض', BadgeTone.warn),
      'failed' => ('فشل', BadgeTone.bad),
      _ => (item.result, BadgeTone.gray),
    };
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Pill.tone(label, tone),
        if (item.isPreview) Pill.tone('dry_run', BadgeTone.tint, ltr: true, mono: true),
      ],
    );
  }

  Widget _literal(String? value, {bool mono = false}) => SelectableText(
    value == null || value.isEmpty ? '—' : value,
    textDirection: TextDirection.ltr,
    maxLines: 3,
    style: TextStyle(
      fontSize: mono ? 12 : 13,
      color: mono ? AppColors.textSub : AppColors.text,
      fontFamily: mono ? 'monospace' : null,
    ),
  );

  Widget _table() => UiTable(
    columns: const [
      UiCol('الوقت (بغداد)', flex: 3, minWidth: 170),
      UiCol('المنفذ', flex: 2, minWidth: 110),
      UiCol('العملية', flex: 3, minWidth: 150),
      UiCol('الهدف', flex: 3, minWidth: 150),
      UiCol('النتيجة', flex: 2, minWidth: 150),
      UiCol('عنوان IP', flex: 2, minWidth: 130),
      UiCol('التفاصيل', flex: 4, minWidth: 220),
    ],
    rows: [
      for (final item in _items)
        UiRow(
          key: ValueKey(item.id),
          cells: [
            _literal(_dateFormat.format(item.baghdadTime), mono: true),
            _literal(item.actor),
            Tooltip(
              message: item.action,
              child: Text(
                item.actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            _literal(item.targetLabel),
            _result(item),
            _literal(item.ip, mono: true),
            item.isPreview && (item.detail == null || item.detail!.isEmpty)
                ? const Text(
                    'معاينة دون تنفيذ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  )
                : _literal(item.detail),
          ],
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    int count(String r) => _items.where((i) => i.result == r).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'سجل النشاط',
          badge: Pill.tone('للقراءة فقط', BadgeTone.gray),
          actions: [
            AppButton(
              label: _loading ? 'جارٍ التحديث…' : 'تحديث',
              icon: LucideIcons.refreshCw,
              style: AppButtonStyle.outline,
              onPressed: _loading ? null : () => _load(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_loaded && _error != null)
          ErrorView(message: _error!, onRetry: () => _load())
        else if (!_loaded)
          const LoadingView()
        else ...[
          KpiGrid(
            children: [
              KpiTile(
                label: 'العمليات المحمّلة',
                value: '${_items.length}',
                icon: LucideIcons.fileText,
                iconBackground: AppColors.tint,
                iconForeground: AppColors.brand,
              ),
              KpiTile(
                label: 'ناجحة',
                value: '${count('success')}',
                icon: LucideIcons.check,
                iconBackground: AppColors.okBg,
                iconForeground: AppColors.green,
              ),
              KpiTile(
                label: 'مرفوضة',
                value: '${count('rejected')}',
                icon: LucideIcons.lock,
                iconBackground: AppColors.warnBg,
                iconForeground: AppColors.warnText,
              ),
              KpiTile(
                label: 'فاشلة',
                value: '${count('failed')}',
                icon: LucideIcons.circleAlert,
                iconBackground: AppColors.badBg,
                iconForeground: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.badBg,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          size: 18,
                          color: AppColors.redDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.redDark,
                            ),
                          ),
                        ),
                        AppButton(
                          label: 'إعادة المحاولة',
                          icon: LucideIcons.refreshCw,
                          style: AppButtonStyle.outline,
                          small: true,
                          onPressed: _loading
                              ? null
                              : () => _load(more: _failedMore),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_items.isEmpty)
                  const EmptyView(
                    message: 'لا توجد عمليات مسجّلة بعد.',
                    icon: LucideIcons.history,
                  )
                else
                  _table(),
                if (_hasMore) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: AppButton(
                      label: _loading
                          ? 'جارٍ التحميل…'
                          : 'تحميل المزيد من السجلات',
                      icon: LucideIcons.clock,
                      style: AppButtonStyle.outline,
                      onPressed: _loading ? null : () => _load(more: true),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'يعرض السجل أحدث العمليات أولاً. الإحصاءات أعلاه للسجلات المحمّلة فقط وليست لكل قاعدة البيانات، وقد يغيب سطر إذا تعذّر حفظه وقت العملية.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
