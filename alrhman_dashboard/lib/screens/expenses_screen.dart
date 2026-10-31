import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/accounts_errors.dart';
import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/money.dart';
import '../models/expense.dart';
import '../models/teacher.dart';
import '../widgets/accounts/accounts_widgets.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
import '../widgets/expenses/expense_dialogs.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/ui/seg_tabs.dart';
import '../widgets/ui/ui_table.dart';

enum _ExpensesView { list, report }

const _monthNames = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

String _monthLabel(String ym) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(ym);
  if (m == null) return ym;
  final i = int.parse(m.group(2)!) - 1;
  return i < 0 || i > 11 ? ym : '${_monthNames[i]} ${m.group(1)}';
}

/// شهور السنة الدراسية `2026-2027`: من آب السنة الأولى إلى تموز الثانية.
List<String> _yearMonths(String academicYear) {
  final m = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(academicYear);
  if (m == null) return const [];
  final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
  String two(int n) => n.toString().padLeft(2, '0');
  return [
    for (var mo = 8; mo <= 12; mo++) '$a-${two(mo)}',
    for (var mo = 1; mo <= 7; mo++) '$b-${two(mo)}',
  ];
}

/// المصروفات والتقرير. بيانات الرواتب حسّاسة؛ الشاشة للمدير فقط.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  _ExpensesView _view = _ExpensesView.list;

  int? _categoryId, _teacherId;
  String? _month;
  ExpenseList? _list;
  List<ExpenseCategory> _categories = const [];
  List<Teacher> _teachers = const [];
  String? _error;
  bool _loading = false;
  int _seq = 0;

  int? _reportCategory;
  ExpenseSummary? _summary;
  String? _summaryError;

  bool _started = false;

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadLookups();
    _load();
  }

  Future<void> _loadLookups() async {
    try {
      final cats = await _api.expenseCategories();
      final teachers = await _api.teachers();
      if (mounted) {
        setState(() {
          _categories = cats;
          _teachers = teachers;
        });
      }
    } on ApiException catch (e) {
      if (mounted) _toastError(e.accountsMessage);
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.expenses(
        categoryId: _categoryId,
        month: _month,
        teacherId: _teacherId,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.accountsMessage;
        _loading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryError = null);
    final wanted = _reportCategory;
    try {
      final s = await _api.expenseSummary(categoryId: wanted);
      if (mounted && wanted == _reportCategory) setState(() => _summary = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _summaryError = e.accountsMessage);
    }
  }

  void _setView(_ExpensesView v) {
    setState(() => _view = v);
    if (v == _ExpensesView.report && _summary == null) _loadSummary();
  }

  void _toastError(String message) => showAppToast(
    context,
    message,
    icon: LucideIcons.circleAlert,
    iconColor: AppColors.red,
  );

  void _refreshAll() {
    _load();
    if (_summary != null) {
      setState(() => _summary = null);
      if (_view == _ExpensesView.report) _loadSummary();
    }
  }

  Future<void> _add() async {
    if (_categories.isEmpty) {
      _toastError('تعذر تحميل الفئات، حدّث الصفحة وحاول مرة أخرى');
      return;
    }
    final saved = await ExpenseFormDialog.show(
      context,
      categories: _categories,
      teachers: _teachers,
      academicYear: _list?.academicYear ?? '',
      onSubmit: (cat, amount, date, note, teacher) => _api.createExpense(
        categoryId: cat,
        amount: amount,
        date: date,
        note: note,
        teacherId: teacher,
      ),
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تم حفظ المصروف');
    _refreshAll();
  }

  Future<void> _addCategory() async {
    final saved = await CategoryDialog.show(
      context,
      existing: _categories,
      onSubmit: (name) => _api.createExpenseCategory(name),
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تمت إضافة الفئة');
    _loadLookups();
  }

  Future<void> _void(Expense e) async {
    final done = await VoidDialog.show(
      context,
      title: 'إلغاء مصروف',
      subtitle: 'يبقى في القائمة بحالة «ملغى» ولا يدخل في المجاميع',
      summary: Row(
        children: [
          Text(
            e.category.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          MoneyText(e.amount),
          const Spacer(),
          Text(
            e.expenseDate,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      onSubmit: (reason) => _api.voidExpense(id: e.id, reason: reason),
    );
    if (!done || !mounted) return;
    showAppToast(context, 'أُلغي المصروف وبقي في السجل');
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final year = _list?.academicYear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المصروفات',
          badge: year == null || year.isEmpty
              ? null
              : Pill.tone(year, BadgeTone.tint, ltr: true),
          actions: [
            AppButton(
              label: 'فئة جديدة',
              icon: LucideIcons.tag,
              style: AppButtonStyle.outline,
              onPressed: _categories.isEmpty ? null : _addCategory,
            ),
          ],
          cta: AppButton(
            label: 'إضافة مصروف',
            icon: LucideIcons.plus,
            style: AppButtonStyle.amber,
            onPressed: _add,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegTabs<_ExpensesView>(
            value: _view,
            onChanged: _setView,
            items: const [
              (_ExpensesView.list, 'قائمة المصروفات'),
              (_ExpensesView.report, 'تقرير السنة'),
            ],
            icons: const [LucideIcons.receipt, LucideIcons.chartColumn],
          ),
        ),
        const SizedBox(height: 20),
        if (_view == _ExpensesView.list) _listView() else _report(),
      ],
    );
  }

  // ------------------------------------------------------------- القائمة

  Widget _listView() {
    final list = _list;
    final months = _yearMonths(list?.academicYear ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 210,
                child: AppDropdown<int?>(
                  value: _categoryId,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'جميع الفئات'),
                    for (final c in _categories) DropdownItem(c.id, c.name),
                  ],
                  onChanged: (v) {
                    setState(() => _categoryId = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 210,
                child: AppDropdown<String?>(
                  value: _month,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'كل الأشهر'),
                    for (final m in months) DropdownItem(m, _monthLabel(m)),
                  ],
                  onChanged: (v) {
                    setState(() => _month = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 230,
                child: AppDropdown<int?>(
                  value: _teacherId,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'كل المعلمين'),
                    for (final t in _teachers) DropdownItem(t.id, t.fullName),
                  ],
                  onChanged: (v) {
                    setState(() => _teacherId = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (list == null)
          _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView()
        else ...[
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          KpiGrid(
            children: [
              KpiTile(
                label: 'مجموع المصروفات (غير الملغاة)',
                value: Money.dinar(list.total),
                icon: LucideIcons.receipt,
              ),
              KpiTile(
                label: 'عدد السجلات',
                value: '${list.expenses.length}',
                icon: LucideIcons.listOrdered,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: list.expenses.isEmpty
                ? const EmptyView(
                    message: 'لا توجد مصروفات مطابقة',
                    icon: LucideIcons.receipt,
                  )
                : UiTable(
                    columns: const [
                      UiCol('التاريخ', flex: 2, minWidth: 120),
                      UiCol('الفئة', flex: 3, minWidth: 140),
                      UiCol('المبلغ', flex: 3, minWidth: 140),
                      UiCol('المعلم / الملاحظة', flex: 4, minWidth: 220),
                      UiCol('الحالة', flex: 3, minWidth: 200),
                      UiCol('الإجراءات', flex: 1, minWidth: 90),
                    ],
                    rows: [for (final e in list.expenses) _row(e)],
                  ),
          ),
        ],
      ],
    );
  }

  UiRow _row(Expense e) {
    final detail = [
      if (e.teacherName != null) e.teacherName!,
      if ((e.note ?? '').isNotEmpty) e.note!,
    ].join(' · ');
    return UiRow(
      key: ValueKey(e.id),
      cells: [
        LtrText(e.expenseDate),
        Text(
          e.category.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: e.voided ? AppColors.textMuted : AppColors.text,
          ),
        ),
        MoneyText(e.amount, strike: e.voided),
        Text(
          detail.isEmpty ? '—' : detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSub),
        ),
        e.voided
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pill.tone('ملغى', BadgeTone.bad),
                  if ((e.voidReason ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        e.voidReason!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              )
            : Pill.tone('فعّال', BadgeTone.ok),
        e.voided
            ? const SizedBox.shrink()
            : IconActionButton.danger(
                icon: LucideIcons.ban,
                tooltip: 'إلغاء المصروف',
                onPressed: () => _void(e),
              ),
      ],
    );
  }

  // -------------------------------------------------------------- التقرير

  Widget _report() {
    final s = _summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 240,
                child: AppDropdown<int?>(
                  value: _reportCategory,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'السنة كاملة'),
                    for (final c in _categories) DropdownItem(c.id, c.name),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _reportCategory = v;
                      _summary = null;
                    });
                    _loadSummary();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _reportCategory == null
                      ? 'المقبوض: دفعات الأقساط غير الملغاة لحسابات هذه السنة.'
                      : 'عند اختيار فئة تُعرض مصروفاتها فقط؛ المقبوض والفرق لا يظهران.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (s == null)
          _summaryError != null
              ? ErrorView(message: _summaryError!, onRetry: _loadSummary)
              : const LoadingView()
        else ...[
          KpiGrid(
            children: [
              KpiTile(
                label: 'المصروفات',
                value: Money.dinar(s.totals.expenses),
                icon: LucideIcons.receipt,
              ),
              KpiTile(
                label: 'المقبوض من الأقساط',
                value: Money.dinar(s.totals.collected),
                icon: LucideIcons.wallet,
              ),
              KpiTile(
                label: 'الفرق',
                value: Money.dinar(s.totals.difference),
                icon: LucideIcons.scale,
                note: 'نقدي: المقبوض ناقص المصروفات، وليس ربحاً',
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'حسب الفئة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                UiTable(
                  columns: const [
                    UiCol('الفئة', flex: 5, minWidth: 200),
                    UiCol('المجموع', flex: 4, minWidth: 160),
                  ],
                  rows: [
                    for (final c in s.byCategory)
                      UiRow(
                        key: ValueKey('c${c.categoryId}'),
                        cells: [
                          Text(c.name, style: const TextStyle(fontSize: 14)),
                          MoneyText(c.total),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'حسب الشهر',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (s.byMonth.isEmpty)
                  const EmptyView(message: 'لا توجد حركة بعد')
                else
                  UiTable(
                    columns: const [
                      UiCol('الشهر', flex: 3, minWidth: 150),
                      UiCol('المصروفات', flex: 3, minWidth: 150),
                      UiCol('المقبوض', flex: 3, minWidth: 150),
                      UiCol('الفرق', flex: 3, minWidth: 150),
                    ],
                    rows: [
                      for (final m in s.byMonth)
                        UiRow(
                          key: ValueKey(m.month),
                          cells: [
                            Text(_monthLabel(m.month)),
                            MoneyText(m.totals.expenses),
                            MoneyText(m.totals.collected),
                            MoneyText(
                              m.totals.difference,
                              color: (m.totals.difference ?? 0) < 0
                                  ? AppColors.red
                                  : AppColors.text,
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
