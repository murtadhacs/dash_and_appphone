import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/accounts_errors.dart';
import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/money.dart';
import '../models/tuition.dart';
import '../widgets/accounts/accounts_widgets.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/app_switch.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/tuition/tuition_dialogs.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/ui/letter_avatar.dart';
import '../widgets/ui/seg_tabs.dart';
import '../widgets/ui/ui_table.dart';

enum _TuitionView { students, grades }

/// الأقساط: قائمة الطلاب بملخصها وفلاترها، وأقساط الصفوف، وتفاصيل قسط طالب.
/// السنة الدراسية الحالية تأتي من الخادم ولا تُحرَّر هنا؛ لتغييرها شاشة منفصلة.
class TuitionScreen extends StatefulWidget {
  final VoidCallback onOpenAcademicYear;
  const TuitionScreen({super.key, required this.onOpenAcademicYear});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  _TuitionView _view = _TuitionView.students;

  // قائمة الطلاب
  final _search = TextEditingController();
  Timer? _debounce;
  String? _grade, _section;
  bool _hasRemaining = false;
  TuitionList? _list;
  List<String> _gradeOptions = const [], _sectionOptions = const [];
  String? _error;
  bool _loading = false;
  int _seq = 0;

  // أقساط الصفوف
  GradeFees? _fees;
  String? _feesError;

  // تفاصيل طالب
  TuitionDetail? _detail;
  String? _detailError;
  int? _openStudent;

  bool _started = false;

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(first: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.tuition(
        grade: _grade,
        section: _section,
        search: _search.text,
        hasRemaining: _hasRemaining,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _list = list;
        _loading = false;
        if (first || _gradeOptions.isEmpty) {
          _gradeOptions = Grades.sorted([
            for (final r in list.rows)
              if ((r.grade ?? '').isNotEmpty) r.grade!,
          ]);
          _sectionOptions = ({
            for (final r in list.rows)
              if ((r.section ?? '').isNotEmpty) r.section!,
          }.toList()..sort());
        }
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.accountsMessage;
        _loading = false;
      });
    }
  }

  Future<void> _loadFees() async {
    setState(() => _feesError = null);
    try {
      final fees = await _api.tuitionFees();
      if (mounted) setState(() => _fees = fees);
    } on ApiException catch (e) {
      if (mounted) setState(() => _feesError = e.accountsMessage);
    }
  }

  Future<void> _openDetail(int studentId) async {
    setState(() {
      _openStudent = studentId;
      _detail = null;
      _detailError = null;
    });
    try {
      final d = await _api.studentTuition(studentId);
      if (mounted && _openStudent == studentId) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted && _openStudent == studentId) {
        setState(() => _detailError = e.accountsMessage);
      }
    }
  }

  void _closeDetail() {
    setState(() {
      _openStudent = null;
      _detail = null;
    });
    _load();
  }

  void _setView(_TuitionView v) {
    setState(() => _view = v);
    if (v == _TuitionView.grades && _fees == null) _loadFees();
  }

  void _toast(String m) => showAppToast(context, m);

  Future<void> _pay() async {
    final d = _detail!;
    final saved = await PaymentDialog.show(
      context,
      row: d.row,
      onSubmit: (amount, date, note) async {
        final updated = await _api.recordPayment(
          studentId: d.row.studentId,
          amount: amount,
          paidAt: date,
          note: note,
        );
        if (mounted) setState(() => _detail = updated);
      },
    );
    if (saved && mounted) _toast('تم تسجيل الدفعة');
  }

  Future<void> _discount() async {
    final d = _detail!;
    final saved = await DiscountDialog.show(
      context,
      detail: d,
      onSubmit: (discount, note) async {
        final updated = await _api.setTuitionDiscount(
          studentId: d.row.studentId,
          discount: discount,
          note: note,
        );
        if (mounted) setState(() => _detail = updated);
      },
    );
    if (saved && mounted) _toast('تم حفظ الخصم');
  }

  Future<void> _void(TuitionPayment p) async {
    final d = _detail!;
    final done = await VoidDialog.show(
      context,
      title: 'إلغاء دفعة',
      subtitle: 'تبقى في السجل بحالة «ملغاة» ولا تدخل في أي مجموع',
      warning:
          'لا يمكن تعديل الدفعة أو حذفها. بعد الإلغاء سجّل الدفعة الصحيحة كدفعة جديدة.',
      summary: Row(
        children: [
          MoneyText(p.amount, size: 15),
          const Spacer(),
          Text(
            'استُلمت ${p.paidAt} · ${d.row.fullName}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      onSubmit: (reason) async {
        final updated = await _api.voidPayment(id: p.id, reason: reason);
        if (mounted) setState(() => _detail = updated);
      },
    );
    if (done && mounted) _toast('أُلغيت الدفعة وبقيت في السجل');
  }

  Future<void> _editFee(GradeFee f) async {
    final saved = await FeeDialog.show(
      context,
      fee: f,
      academicYear: _fees?.academicYear ?? '',
      onSubmit: (fee, apply) async {
        final n = await _api.setTuitionFee(
          grade: f.grade,
          fee: fee,
          applyToExisting: apply,
        );
        if (mounted && apply) _toast('أُعيد تسعير $n حساب');
      },
    );
    if (!saved || !mounted) return;
    _toast('تم حفظ القسط');
    _loadFees();
    _load(first: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_openStudent != null) return _detailView();
    final year = _list?.academicYear ?? _fees?.academicYear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأقساط',
          badge: year == null || year.isEmpty
              ? null
              : Pill.tone(year, BadgeTone.tint, ltr: true),
          actions: [
            AppButton(
              label: 'تغيير السنة الدراسية',
              icon: LucideIcons.calendarRange,
              style: AppButtonStyle.outline,
              onPressed: widget.onOpenAcademicYear,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegTabs<_TuitionView>(
            value: _view,
            onChanged: _setView,
            items: const [
              (_TuitionView.students, 'أقساط الطلاب'),
              (_TuitionView.grades, 'أقساط الصفوف'),
            ],
            icons: const [LucideIcons.users, LucideIcons.receipt],
          ),
        ),
        const SizedBox(height: 20),
        if (_view == _TuitionView.students) _students() else _grades(),
      ],
    );
  }

  // ------------------------------------------------------- قائمة الطلاب

  Widget _students() {
    final list = _list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: AppTextField(
                  controller: _search,
                  prefixIcon: LucideIcons.search,
                  hint: 'ابحث باسم الطالب',
                  fill: AppColors.canvas,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), _load);
                  },
                ),
              ),
              SizedBox(
                width: 230,
                child: AppDropdown<String?>(
                  value: _grade,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'جميع الصفوف'),
                    for (final g in _gradeOptions) DropdownItem(g, g),
                  ],
                  onChanged: (v) {
                    setState(() => _grade = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: AppDropdown<String?>(
                  value: _section,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'جميع الشعب'),
                    for (final s in _sectionOptions) DropdownItem(s, s),
                  ],
                  onChanged: (v) {
                    setState(() => _section = v);
                    _load();
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSwitch(
                    value: _hasRemaining,
                    onChanged: (v) {
                      setState(() => _hasRemaining = v);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'عليه متبقٍ فقط',
                    style: TextStyle(fontSize: 13, color: AppColors.textSub),
                  ),
                ],
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
                label: 'مجموع الأقساط',
                value: Money.dinar(list.summary.totalFee),
                icon: LucideIcons.receipt,
              ),
              KpiTile(
                label: 'مجموع الخصومات',
                value: Money.dinar(list.summary.totalDiscount),
                icon: LucideIcons.tag,
              ),
              KpiTile(
                label: 'المقبوض',
                value: Money.dinar(list.summary.totalCollected),
                icon: LucideIcons.wallet,
              ),
              KpiTile(
                label: 'المتبقي',
                value: Money.dinar(list.summary.totalRemaining),
                icon: LucideIcons.hourglass,
              ),
            ],
          ),
          if (list.summary.notSetCount > 0) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Pill.tone(
                'قسط غير محدد: ${list.summary.notSetCount}',
                BadgeTone.warn,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: list.rows.isEmpty
                ? const EmptyView(message: 'لا يوجد طلاب مطابقون')
                : UiTable(
                    columns: const [
                      UiCol('الطالب', flex: 4, minWidth: 220),
                      UiCol('الصف والشعبة', flex: 4, minWidth: 220),
                      UiCol('القسط', flex: 3, minWidth: 130),
                      UiCol('الخصم', flex: 2, minWidth: 110),
                      UiCol('المقبوض', flex: 3, minWidth: 130),
                      UiCol('المتبقي', flex: 3, minWidth: 140),
                    ],
                    rows: [for (final r in list.rows) _studentRow(r)],
                  ),
          ),
        ],
      ],
    );
  }

  UiRow _studentRow(TuitionRow r) {
    final dim = !r.isActive;
    return UiRow(
      key: ValueKey(r.studentId),
      onTap: () => _openDetail(r.studentId),
      cells: [
        PersonCell(
          avatar: LetterAvatar(name: r.fullName),
          title: r.fullName,
          subtitle: dim ? 'غادر المدرسة' : null,
        ),
        Text(
          r.gradeSection,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: dim ? AppColors.textMuted : AppColors.text,
          ),
        ),
        r.feeSet ? MoneyText(r.fee) : const NotSetBadge(),
        MoneyText(r.discount),
        MoneyText(r.paid),
        r.remaining == null
            ? const NotSetBadge()
            : MoneyText(
                r.remaining,
                color: r.remaining! > 0 ? AppColors.warnDeep : AppColors.green,
              ),
      ],
    );
  }

  // -------------------------------------------------------- أقساط الصفوف

  Widget _grades() {
    final fees = _fees;
    if (fees == null) {
      return _feesError != null
          ? ErrorView(message: _feesError!, onRetry: _loadFees)
          : const LoadingView();
    }
    final sorted = [...fees.fees]
      ..sort((a, b) => Grades.compare(a.grade, b.grade));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: sorted.isEmpty
          ? const EmptyView(message: 'لا توجد صفوف بعد')
          : UiTable(
              columns: const [
                UiCol('الصف', flex: 5, minWidth: 220),
                UiCol('القسط السنوي', flex: 4, minWidth: 180),
                UiCol('آخر تحديث', flex: 3, minWidth: 150),
                UiCol('الإجراءات', flex: 1, minWidth: 90),
              ],
              rows: [
                for (final f in sorted)
                  UiRow(
                    key: ValueKey(f.grade),
                    cells: [
                      Text(
                        f.grade,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      f.fee == null ? const NotSetBadge() : MoneyText(f.fee),
                      f.updatedAt == null
                          ? const Text(
                              '—',
                              style: TextStyle(color: AppColors.textMuted),
                            )
                          : LtrText(
                              f.updatedAt!.substring(
                                0,
                                f.updatedAt!.length.clamp(0, 10),
                              ),
                            ),
                      IconActionButton(
                        icon: LucideIcons.pencil,
                        tooltip: 'تعديل القسط',
                        onPressed: () => _editFee(f),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  // --------------------------------------------------------- تفاصيل طالب

  Widget _detailView() {
    final d = _detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: d?.row.fullName ?? 'قسط الطالب',
          badge: d == null || d.academicYear.isEmpty
              ? null
              : Pill.tone(d.academicYear, BadgeTone.tint, ltr: true),
          actions: [
            AppButton(
              label: 'رجوع للقائمة',
              icon: LucideIcons.arrowRight,
              style: AppButtonStyle.outline,
              onPressed: _closeDetail,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (d == null)
          _detailError != null
              ? ErrorView(
                  message: _detailError!,
                  onRetry: () => _openDetail(_openStudent!),
                )
              : const LoadingView()
        else ...[
          AppCard(
            child: Wrap(
              spacing: 40,
              runSpacing: 16,
              children: [
                FigureCard(
                  label: 'الصف والشعبة',
                  value: Text(
                    d.row.gradeSection,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FigureCard(
                  label: 'القسط',
                  value: d.row.feeSet
                      ? MoneyText(d.row.fee, size: 16)
                      : const NotSetBadge(),
                ),
                FigureCard(
                  label: d.discountNote == null || d.discountNote!.isEmpty
                      ? 'الخصم'
                      : 'الخصم · ${d.discountNote}',
                  value: MoneyText(d.row.discount, size: 16),
                ),
                FigureCard(
                  label: 'المقبوض',
                  value: MoneyText(d.row.paid, size: 16),
                ),
                FigureCard(
                  label: 'المتبقي',
                  value: d.row.remaining == null
                      ? const NotSetBadge()
                      : MoneyText(
                          d.row.remaining,
                          size: 18,
                          color: AppColors.warnDeep,
                        ),
                ),
              ],
            ),
          ),
          if (!d.row.isActive) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Pill.tone('غادر المدرسة', BadgeTone.gray),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'تسجيل دفعة',
                icon: LucideIcons.wallet,
                style: AppButtonStyle.amber,
                // دون قسط محدد لا تُقبل دفعة (409)، فنوجّه المدير لتحديد القسط.
                onPressed: d.row.feeSet ? _pay : null,
                tooltip: d.row.feeSet ? null : 'حدد قسط الصف أولاً',
              ),
              AppButton(
                label: 'تحديد الخصم',
                icon: LucideIcons.tag,
                style: AppButtonStyle.outline,
                onPressed: d.row.feeSet ? _discount : null,
                tooltip: d.row.feeSet ? null : 'حدد قسط الصف أولاً',
              ),
            ],
          ),
          if (!d.row.feeSet) ...[
            const SizedBox(height: 12),
            const DialogNote(
              'لم يحدد القسط لهذا الصف بعد. حدّده من تبويب «أقساط الصفوف» ثم سجّل الدفعات.',
              tone: NoteTone.warn,
            ),
          ],
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سجل الدفعات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (d.payments.isEmpty)
                  const EmptyView(message: 'لا توجد دفعات بعد')
                else
                  UiTable(
                    columns: const [
                      UiCol('المبلغ', flex: 3, minWidth: 140),
                      UiCol('تاريخ الاستلام', flex: 3, minWidth: 130),
                      UiCol('ملاحظة', flex: 4, minWidth: 160),
                      UiCol('الحالة', flex: 4, minWidth: 220),
                      UiCol('الإجراءات', flex: 1, minWidth: 90),
                    ],
                    rows: [
                      for (final p in d.payments)
                        UiRow(
                          key: ValueKey(p.id),
                          cells: [
                            MoneyText(p.amount, strike: p.voided),
                            LtrText(p.paidAt),
                            Text(
                              (p.note ?? '').isEmpty ? '—' : p.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            p.voided
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Pill.tone('ملغاة', BadgeTone.bad),
                                      if ((p.voidReason ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            p.voidReason!,
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
                                : Pill.tone('فعّالة', BadgeTone.ok),
                            p.voided
                                ? const SizedBox.shrink()
                                : IconActionButton.danger(
                                    icon: LucideIcons.ban,
                                    tooltip: 'إلغاء الدفعة',
                                    onPressed: () => _void(p),
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
