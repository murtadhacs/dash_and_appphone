import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/app_dropdown.dart';
import '../common/app_text_field.dart';

/// شريط البحث والفلاتر وزر إضافة طالب. قوائم الصف والشعبة تُبنى من بيانات الطلاب.
class StudentsToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> grades;
  final List<String> sections;
  final String gradeFilter;
  final String sectionFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onSectionChanged;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  const StudentsToolbar({
    super.key,
    required this.searchController,
    required this.grades,
    required this.sections,
    required this.gradeFilter,
    required this.sectionFilter,
    required this.onSearchChanged,
    required this.onGradeChanged,
    required this.onSectionChanged,
    required this.onReset,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final search = AppTextField(
      controller: searchController,
      onChanged: onSearchChanged,
      hint: 'ابحث باسم الطالب، ولي الأمر، الهاتف أو معرّف البصمة...',
      prefixIcon: Icons.search,
      suffix: searchController.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                searchController.clear();
                onSearchChanged('');
              },
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textMuted,
            ),
    );

    final grade = AppDropdown<String>(
      value: grades.contains(gradeFilter) ? gradeFilter : 'all',
      items: [
        const DropdownItem('all', 'جميع الصفوف الدراسية'),
        for (final g in grades) DropdownItem(g, g),
      ],
      onChanged: onGradeChanged,
    );
    final section = AppDropdown<String>(
      value: sections.contains(sectionFilter) ? sectionFilter : 'all',
      items: [
        const DropdownItem('all', 'كافة الشُعب'),
        for (final s in sections) DropdownItem(s, s),
      ],
      onChanged: onSectionChanged,
    );
    final reset = Tooltip(
      message: 'إعادة ضبط الفلاتر',
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.border,
          onTap: onReset,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.filter_alt_off_outlined,
              size: 16,
              color: AppColors.textSub,
            ),
          ),
        ),
      ),
    );
    final add = AppButton(
      label: 'إضافة طالب جديد',
      icon: Icons.person_add_alt,
      onPressed: onAdd,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 940;
          return wide
              ? Row(
                  children: [
                    SizedBox(width: 320, child: search),
                    const SizedBox(width: 10),
                    SizedBox(width: 192, child: grade),
                    const SizedBox(width: 10),
                    SizedBox(width: 144, child: section),
                    const SizedBox(width: 10),
                    reset,
                    const Spacer(),
                    add,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: grade),
                        const SizedBox(width: 10),
                        Expanded(child: section),
                        const SizedBox(width: 10),
                        reset,
                      ],
                    ),
                    const SizedBox(height: 10),
                    add,
                  ],
                );
        },
      ),
    );
  }
}
