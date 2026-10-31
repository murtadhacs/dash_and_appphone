import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../core/baghdad_time.dart';
import '../data/parent_data.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// `1500000` ← `1,500,000` بأرقام لاتينية.
String formatDinar(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// `1 تشرين الأول 2026 · 9:30 ص`، بتوقيت بغداد.
String formatTuitionUpdate(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${BaghdadTime.monthNames[t.month - 1]} ${t.year} · '
      '$h:$m ${t.hour < 12 ? 'ص' : 'م'}';
}

/// المتبقي من القسط لكل ابن، للقراءة فقط. لا قسط ولا خصم ولا دفعات هنا.
class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key, required this.data});

  final ParentData data;

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  List<ChildTuition>? _items;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.data.api.tuition();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _classOf(int studentId) {
    for (final s in widget.data.students) {
      if (s.id != studentId) continue;
      final parts = [s.grade, s.section].where((x) => x.isNotEmpty);
      return parts.join(' — ');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final year = items == null || items.isEmpty
        ? null
        : items.first.academicYear;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: TabPageScroll(
        onRefresh: _load,
        horizontalPadding: 16,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Tap(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 24,
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المتبقي من القسط',
                        style: AppText.style(
                          size: 16,
                          weight: AppText.extrabold,
                        ),
                      ),
                      if (year != null)
                        Row(
                          children: [
                            Text(
                              'العام الدراسي ',
                              style: AppText.style(
                                size: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              year,
                              textDirection: TextDirection.ltr,
                              style: AppText.style(
                                size: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (items == null)
            _error != null
                ? _ErrorCard(message: _error!, onRetry: _load)
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ),
                  )
          else if (items.isEmpty)
            const _EmptyCard()
          else ...[
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChildCard(item: t, className: _classOf(t.studentId)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'يُحدَّث المبلغ عند تسجيل أي دفعة أو خصم في المدرسة. '
                'للاستفسار تواصل مع إدارة المدرسة.',
                style: AppText.style(
                  size: 10,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.item, required this.className});

  final ChildTuition item;
  final String className;

  @override
  Widget build(BuildContext context) {
    final remaining = item.remaining;
    final (dot, label) = remaining == null
        ? (AppColors.faint, 'لم يُحدَّد')
        : remaining == 0
        ? (AppColors.present, 'مسدّد')
        : (AppColors.holiday, 'متبقٍ');
    final updated = item.lastUpdated;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(size: 15, weight: AppText.extrabold),
                    ),
                    if (className.isNotEmpty)
                      Text(
                        className,
                        style: AppText.style(
                          size: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppText.style(size: 10, weight: AppText.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inset,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتبقي من القسط',
                  style: AppText.style(
                    size: 10,
                    weight: AppText.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                if (remaining == null)
                  Text(
                    'لم يُحدَّد القسط بعد',
                    style: AppText.style(
                      size: 18,
                      weight: AppText.extrabold,
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatDinar(remaining),
                        textDirection: TextDirection.ltr,
                        style: AppText.style(
                          size: 26,
                          weight: AppText.extrabold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'د.ع',
                        style: AppText.style(
                          size: 12,
                          weight: AppText.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  updated == null
                      ? 'لا يوجد تحديث بعد'
                      : 'آخر تحديث: ${formatTuitionUpdate(updated)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(size: 10, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppShadows.sm,
    ),
    child: Text(
      'لا يوجد أبناء فعّالون لعرض القسط.',
      textAlign: TextAlign.center,
      style: AppText.style(size: 12, color: AppColors.textMuted),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppShadows.sm,
    ),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.style(size: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Tap(
          onTap: onRetry,
          child: Text(
            'إعادة المحاولة',
            style: AppText.style(
              size: 12,
              weight: AppText.bold,
              color: AppColors.brandPurple,
            ),
          ),
        ),
      ],
    ),
  );
}
