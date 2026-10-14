import 'package:flutter/material.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/student.dart';
import '../services/excel_export_service.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/students/delete_student_dialog.dart';
import '../widgets/students/pin_reveal_dialog.dart';
import '../widgets/students/student_form_dialog.dart';
import '../widgets/students/students_stats_row.dart';
import '../widgets/students/students_table_card.dart';
import '../widgets/students/students_toolbar.dart';

/// شاشة الطلاب وأولياء الأمور (بيانات حيّة من `/api/admin/students`).
class StudentsScreen extends StatefulWidget {
  /// يفتح نافذة الإضافة تلقائياً (اختصار من لوحة التحكم).
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;

  const StudentsScreen({
    super.key,
    this.openAddOnStart = false,
    this.onStartHandled,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _search = TextEditingController();
  String _grade = 'all';
  String _section = 'all';

  List<Student>? _students;
  String? _error;
  bool _loading = true;

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_students == null && _loading && _error == null) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.students();
      if (!mounted) return;
      setState(() {
        _students = list;
        _loading = false;
      });
      if (widget.openAddOnStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onStartHandled?.call();
          _openAdd();
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<String> _distinct(String? Function(Student) pick) {
    final set = <String>{
      for (final s in _students ?? const <Student>[])
        if ((pick(s) ?? '').trim().isNotEmpty) pick(s)!.trim(),
    };
    return set.toList()..sort();
  }

  List<Student> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return (_students ?? const <Student>[]).where((s) {
      final matchSearch =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.parentName.toLowerCase().contains(q) ||
          s.parentPhone.contains(q) ||
          s.rfidTag.toLowerCase().contains(q);
      final matchGrade = _grade == 'all' || (s.grade ?? '') == _grade;
      final matchSection = _section == 'all' || (s.section ?? '') == _section;
      return matchSearch && matchGrade && matchSection;
    }).toList();
  }

  /// أرقام أولياء الأمور المسجّلين حالياً (لتحديد هل الرقم لولي أمر جديد).
  Set<String> get _knownParentPhones => {
    for (final s in _students ?? const <Student>[])
      if (s.parentPhone.isNotEmpty) s.parentPhone,
  };

  Future<void> _openAdd() async {
    final saved = await StudentFormDialog.show(
      context,
      knownParentPhones: _knownParentPhones,
      knownStudents: _students ?? const [],
      knownGrades: _distinct((s) => s.grade),
      knownSections: _distinct((s) => s.section),
      onSubmit: (i) => _api.createStudent(
        name: i.name,
        parentName: i.parentName,
        parentPhone: i.parentPhone,
        parentPin: i.parentPin,
        rfidTag: i.rfidTag!,
        grade: i.grade,
        section: i.section,
      ),
    );
    if (saved == null || !mounted) return;
    showAppToast(context, 'تمت إضافة الطالب الجديد بنجاح');
    _load();
    await _revealPin(saved);
  }

  Future<void> _openEdit(Student s) async {
    final saved = await StudentFormDialog.show(
      context,
      editing: s,
      knownParentPhones: _knownParentPhones,
      knownStudents: _students ?? const [],
      knownGrades: _distinct((s) => s.grade),
      knownSections: _distinct((s) => s.section),
      onSubmit: (i) => _api.updateStudent(
        id: s.id,
        name: i.name,
        parentName: i.parentName,
        parentPhone: i.parentPhone,
        parentPin: i.parentPin,
        rfidTag: i.rfidTag,
        grade: i.grade,
        section: i.section,
      ),
    );
    if (saved == null || !mounted) return;
    showAppToast(context, 'تم تحديث بيانات الطالب بنجاح');
    _load();
    await _revealPin(saved);
  }

  /// بعد حفظ ناجح بأي رمز جديد: يُعرض مرة واحدة ليسلّمه المدير لولي الأمر.
  Future<void> _revealPin(StudentInput saved) async {
    final pin = saved.parentPin;
    if (pin == null || !mounted) return;
    await PinRevealDialog.show(context, parentName: saved.parentName, pin: pin);
  }

  Future<void> _confirmDelete(Student s) async {
    final ok = await DeleteStudentDialog.show(context, s);
    if (!ok || !mounted) return;
    try {
      await _api.deactivateStudent(s.id);
      if (!mounted) return;
      showAppToast(context, 'تم تعطيل الطالب');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toastError(e.message);
    }
  }

  Future<void> _exportExcel() async {
    try {
      final saved = await ExcelExportService.exportStudents(_filtered);
      if (!saved || !mounted) return;
      showAppToast(context, 'تم حفظ كشف الطلاب بصيغة Excel');
    } catch (_) {
      if (!mounted) return;
      _toastError('تعذر تصدير الملف');
    }
  }

  void _toastError(String message) => showAppToast(
    context,
    message,
    icon: Icons.error_outline,
    iconColor: AppColors.red,
  );

  void _reset() => setState(() {
    _search.clear();
    _grade = 'all';
    _section = 'all';
  });

  @override
  Widget build(BuildContext context) {
    if (_students == null) {
      return _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : const LoadingView();
    }

    return Column(
      children: [
        StudentsStatsRow(students: _students!),
        const SizedBox(height: 20),
        StudentsToolbar(
          searchController: _search,
          grades: _distinct((s) => s.grade),
          sections: _distinct((s) => s.section),
          gradeFilter: _grade,
          sectionFilter: _section,
          onSearchChanged: (_) => setState(() {}),
          onGradeChanged: (v) => setState(() => _grade = v),
          onSectionChanged: (v) => setState(() => _section = v),
          onReset: _reset,
          onAdd: _openAdd,
        ),
        const SizedBox(height: 20),
        StudentsTableCard(
          students: _filtered,
          total: _students!.length,
          onEdit: _openEdit,
          onDelete: _confirmDelete,
          onExport: _exportExcel,
        ),
      ],
    );
  }
}
