import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/activity_log.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_data_table.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/icon_tile.dart';
import '../widgets/common/pill.dart';
import '../widgets/common/pulse_dot.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_title.dart';

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

  Widget _result(String result) {
    final (label, background, foreground) = switch (result) {
      'success' => ('نجاح', AppColors.greenSoft, AppColors.greenDeep),
      'rejected' => ('طلب مرفوض', AppColors.warnSoft, AppColors.warnDeep),
      'failed' => ('خطأ', AppColors.redSoft, AppColors.redDark),
      _ => (result, AppColors.surfaceMuted, AppColors.textSub),
    };
    return Pill(label: label, background: background, foreground: foreground);
  }

  Widget _literal(String? value, {bool mono = false}) => SelectableText(
    value == null || value.isEmpty ? '—' : value,
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontSize: 12,
      fontWeight: mono ? FontWeight.w600 : FontWeight.normal,
      color: mono ? AppColors.textSub : AppColors.text,
      fontFamily: mono ? 'monospace' : null,
    ),
  );

  Widget _header(BuildContext context) {
    final titles = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأحدث أولاً • 50 عملية في الصفحة • الوقت بتوقيت بغداد',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
      ],
    );

    final refresh = Tooltip(
      message: 'تحديث السجل',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.surfaceMuted,
          onTap: _loading ? null : () => _load(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: SpinningIcon(
                icon: Icons.refresh,
                spinning: _loading,
                color: _loading ? AppColors.primary : AppColors.textSub,
              ),
            ),
          ),
        ),
      ),
    );

    if (MediaQuery.sizeOf(context).width >= Breakpoints.md) {
      return Row(
        children: [
          Expanded(child: titles),
          const SizedBox(width: 16),
          refresh,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titles, const SizedBox(height: 16), refresh],
    );
  }

  Widget _kpis() {
    int count(String r) => _items.where((i) => i.result == r).length;
    return ResponsiveGrid(
      columns: const {0: 1, 640: 2, 1280: 4},
      children: [
        _StatCard(
          label: 'العمليات المعروضة',
          value: '${_items.length}',
          icon: Icons.list_alt_outlined,
          iconBackground: AppColors.accentSoft,
          iconForeground: AppColors.brand,
        ),
        _StatCard(
          label: 'ناجحة',
          value: '${count('success')}',
          valueColor: AppColors.green,
          icon: Icons.check_circle_outline,
          iconBackground: AppColors.greenSoft,
          iconForeground: AppColors.greenDark,
        ),
        _StatCard(
          label: 'طلبات مرفوضة',
          value: '${count('rejected')}',
          valueColor: AppColors.warnDark,
          icon: Icons.block_outlined,
          iconBackground: AppColors.warnSoft,
          iconForeground: AppColors.warnDeep,
        ),
        _StatCard(
          label: 'أخطاء',
          value: '${count('failed')}',
          valueColor: AppColors.red,
          icon: Icons.error_outline,
          iconBackground: AppColors.redSoft,
          iconForeground: AppColors.redDark,
        ),
      ],
    );
  }

  Widget _table() => AppDataTable(
    dataRowHeight: 56,
    dataRowMaxHeight: 180,
    columns: [
      tableColumn('الوقت'),
      tableColumn('من'),
      tableColumn('الإجراء'),
      tableColumn('الهدف'),
      tableColumn('النتيجة'),
      tableColumn('عنوان IP'),
      tableColumn('التفصيل'),
    ],
    rows: [
      for (final item in _items)
        DataRow(
          key: ValueKey(item.id),
          cells: [
            DataCell(
              _literal(_dateFormat.format(item.baghdadTime), mono: true),
            ),
            DataCell(_literal(item.actor)),
            DataCell(
              Tooltip(
                message: item.action,
                child: Text(
                  item.actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(SizedBox(width: 150, child: _literal(item.targetLabel))),
            DataCell(_result(item.result)),
            DataCell(_literal(item.ip, mono: true)),
            DataCell(
              SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isPreview) ...[
                        const Pill(
                          label: 'معاينة • dry_run',
                          icon: Icons.visibility_outlined,
                          background: AppColors.accentSoft,
                          foreground: AppColors.brand,
                        ),
                        const SizedBox(height: 6),
                      ],
                      _literal(item.detail),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    ],
  );

  Widget _logCard() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          icon: Icons.manage_history,
          title: 'العمليات المسجّلة',
          subtitle: 'كل إجراء نفّذه المستخدمون على النظام ونتيجته',
        ),
        const SizedBox(height: 16),
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
        ],
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.redDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.redDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : () => _load(more: _failedMore),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_items.isEmpty)
          const EmptyView(
            message: 'لا توجد عمليات مسجّلة بعد.',
            icon: Icons.history,
          )
        else
          _table(),
        if (_hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: _loading ? 'جارٍ التحميل…' : 'تحميل المزيد',
              icon: Icons.expand_more,
              style: AppButtonStyle.soft,
              onPressed: _loading ? null : () => _load(more: true),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'السجل للقراءة فقط ويُحفظ بأفضل جهد؛ قد يغيب سطر إذا تعذّر حفظه في قاعدة البيانات وقت العملية.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(context),
      const SizedBox(height: 20),
      if (!_loaded && _error != null)
        ErrorView(message: _error!, onRetry: () => _load())
      else if (!_loaded)
        const LoadingView()
      else ...[
        _kpis(),
        const SizedBox(height: 20),
        _logCard(),
      ],
    ],
  );
}

/// بطاقة مؤشر بنفس شكل مؤشرات لوحة التحكم.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    this.valueColor = AppColors.text,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        IconTile(
          icon: icon,
          background: iconBackground,
          foreground: iconForeground,
        ),
      ],
    ),
  );
}
