import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/accounts_errors.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../core/money.dart';
import '../../models/tuition.dart';
import '../accounts/accounts_widgets.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';

/// هيكل مشترك لنوافذ الأقساط: نموذج + رسالة خطأ + زر حفظ يمنع الضغط المزدوج.
abstract class _AccountsFormState<T extends StatefulWidget> extends State<T> {
  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;

  Future<void> run(Future<void> Function() action) async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = e.accountsMessage;
      });
    }
  }

  Widget errorNote() => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DialogNote(error!, tone: NoteTone.bad),
        );

  Widget actions(String label, IconData icon, VoidCallback submit) =>
      DialogActions(
        children: [
          AppButton(
            label: 'إلغاء',
            style: AppButtonStyle.outline,
            onPressed: saving ? null : () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: saving ? 'جارٍ الحفظ...' : label,
            icon: icon,
            style: AppButtonStyle.amber,
            onPressed: saving ? null : submit,
          ),
        ],
      );
}

class _WhoCard extends StatelessWidget {
  final TuitionRow row;
  const _WhoCard(this.row);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  row.gradeSection,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'المتبقي',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              row.remaining == null
                  ? const NotSetBadge()
                  : MoneyText(row.remaining),
            ],
          ),
        ],
      ),
    );
  }
}

/// تسجيل دفعة نقدية. الدفعة لا تُعدَّل ولا تُحذف، وأكبر من المتبقي ترفضها (409).
class PaymentDialog extends StatefulWidget {
  final TuitionRow row;
  final Future<void> Function(int amount, DateTime date, String note) onSubmit;
  const PaymentDialog({super.key, required this.row, required this.onSubmit});

  static Future<bool> show(
    BuildContext context, {
    required TuitionRow row,
    required Future<void> Function(int amount, DateTime date, String note)
    onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentDialog(row: row, onSubmit: onSubmit),
      ) ??
      false;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends _AccountsFormState<PaymentDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = BaghdadTime.today();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 540,
      icon: LucideIcons.wallet,
      title: 'تسجيل دفعة',
      subtitle: 'نقد مستلم في المدرسة',
      onClose: saving ? () {} : null,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            errorNote(),
            _WhoCard(widget.row),
            const SizedBox(height: 16),
            const FieldLabel('المبلغ', required: true),
            const SizedBox(height: 6),
            MoneyField(controller: _amount, hint: 'مثال: 500000'),
            const SizedBox(height: 6),
            const Text(
              'أعداد صحيحة بالدينار فقط، ولا يزيد على المتبقي.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const FieldLabel('تاريخ الاستلام', hint: 'ليس في المستقبل'),
            const SizedBox(height: 6),
            DateField(
              value: _date,
              lastDate: BaghdadTime.today(),
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 16),
            const FieldLabel('ملاحظة', hint: 'اختياري · حتى 200 حرف'),
            const SizedBox(height: 6),
            AppTextField(controller: _note, maxLength: 200),
            const SizedBox(height: 12),
            actions(
              'تسجيل الدفعة',
              LucideIcons.check,
              () => run(
                () => widget.onSubmit(
                  Money.parse(_amount.text)!,
                  _date,
                  _note.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تحديد الخصم: مبلغ ثابت واحد للسنة يستبدل السابق؛ 0 بلا ملاحظة يلغيه.
class DiscountDialog extends StatefulWidget {
  final TuitionDetail detail;
  final Future<void> Function(int discount, String note) onSubmit;
  const DiscountDialog({
    super.key,
    required this.detail,
    required this.onSubmit,
  });

  static Future<bool> show(
    BuildContext context, {
    required TuitionDetail detail,
    required Future<void> Function(int discount, String note) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DiscountDialog(detail: detail, onSubmit: onSubmit),
      ) ??
      false;

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends _AccountsFormState<DiscountDialog> {
  late final _amount = TextEditingController(
    text: widget.detail.row.discount == 0
        ? ''
        : Money.format(widget.detail.row.discount),
  );
  late final _note = TextEditingController(text: widget.detail.discountNote);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.detail.row;
    return AppDialog(
      maxWidth: 540,
      icon: LucideIcons.tag,
      title: 'تحديد الخصم',
      subtitle: 'مبلغ ثابت واحد للسنة، يستبدل الخصم السابق',
      onClose: saving ? () {} : null,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            errorNote(),
            _WhoCard(row),
            const SizedBox(height: 16),
            const FieldLabel('مبلغ الخصم', required: true),
            const SizedBox(height: 6),
            MoneyField(controller: _amount, allowZero: true, hint: '0'),
            const SizedBox(height: 6),
            const Text(
              'لا يتجاوز القسط ولا ما تبقى بعد الدفعات. اكتب 0 بلا ملاحظة لإلغاء الخصم.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const FieldLabel('ملاحظة الخصم', hint: 'اختياري · حتى 200 حرف'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _note,
              maxLength: 200,
              hint: 'مثال: خصم الأخوة',
            ),
            const SizedBox(height: 12),
            const DialogNote(
              'أول خصم أو دفعة في السنة يُنشئ حساب الطالب ويجمّد صفه وقسطه لهذه السنة.',
            ),
            const SizedBox(height: 16),
            actions(
              'حفظ الخصم',
              LucideIcons.check,
              () => run(
                () => widget.onSubmit(
                  Money.parseAllowZero(_amount.text)!,
                  _note.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قسط صف للسنة الحالية. «تصحيح أقساط الطلاب الحاليين» يعيد تسعير كل حساب
/// موجود للصف، لذا يحتاج تأكيداً صريحاً، وهو كله أو لا شيء (409).
class FeeDialog extends StatefulWidget {
  final GradeFee fee;
  final String academicYear;
  final Future<void> Function(int fee, bool applyToExisting) onSubmit;
  const FeeDialog({
    super.key,
    required this.fee,
    required this.academicYear,
    required this.onSubmit,
  });

  static Future<bool> show(
    BuildContext context, {
    required GradeFee fee,
    required String academicYear,
    required Future<void> Function(int fee, bool applyToExisting) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            FeeDialog(fee: fee, academicYear: academicYear, onSubmit: onSubmit),
      ) ??
      false;

  @override
  State<FeeDialog> createState() => _FeeDialogState();
}

class _FeeDialogState extends _AccountsFormState<FeeDialog> {
  late final _amount = TextEditingController(
    text: widget.fee.fee == null ? '' : Money.format(widget.fee.fee!),
  );
  bool _reprice = false, _confirmed = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 560,
      icon: LucideIcons.receipt,
      title: 'تعديل قسط الصف',
      subtitle: '${widget.fee.grade} · السنة ${widget.academicYear}',
      onClose: saving ? () {} : null,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            errorNote(),
            const FieldLabel('القسط السنوي', required: true),
            const SizedBox(height: 6),
            MoneyField(controller: _amount, hint: 'مثال: 1500000'),
            const SizedBox(height: 12),
            const DialogNote(
              'الطلاب الذين لم تُسجَّل لهم دفعة أو خصم يتبعون القسط الجديد فوراً. '
              'من لهم حساب يبقى قسطهم مجمّداً ما لم تختر التصحيح أدناه.',
            ),
            const SizedBox(height: 12),
            ConfirmCheck(
              value: _reprice,
              onChanged: saving
                  ? null
                  : (v) => setState(() {
                      _reprice = v;
                      if (!_reprice) _confirmed = false;
                    }),
              label: 'تصحيح أقساط الطلاب الحاليين في هذا الصف',
            ),
            if (_reprice) ...[
              const DialogNote(
                'سيُعاد تسعير كل طالب في هذا الصف للسنة الحالية بالقسط أعلاه، '
                'حتى من سُجّلت له دفعات. العملية كلها أو لا شيء، وتُرفض إن جعلت رصيد أحدهم سالباً.',
                tone: NoteTone.warn,
              ),
              ConfirmCheck(
                value: _confirmed,
                onChanged: saving
                    ? null
                    : (v) => setState(() => _confirmed = v),
                label:
                    'أفهم أن هذا يغيّر قسط كل طالب في الصف، وأنه إجراء تصحيحي لا اعتيادي.',
              ),
            ],
            const SizedBox(height: 12),
            actions(
              _reprice ? 'تصحيح الأقساط' : 'حفظ القسط',
              _reprice ? LucideIcons.refreshCw : LucideIcons.check,
              _reprice && !_confirmed
                  ? () => setState(
                      () => error = 'أكّد فهمك للتصحيح بتأشير المربع أولاً',
                    )
                  : () => run(
                      () =>
                          widget.onSubmit(Money.parse(_amount.text)!, _reprice),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
