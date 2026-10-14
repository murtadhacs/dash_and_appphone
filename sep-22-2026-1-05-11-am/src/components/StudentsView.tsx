import React, { useState, useMemo } from 'react';
import { 
  Users, 
  TrendingUp, 
  CheckCircle2, 
  KeyRound, 
  Search, 
  X, 
  FilterX, 
  UserPlus, 
  FileSpreadsheet, 
  Edit3, 
  Trash2, 
  Phone, 
  Radio, 
  BadgeHelp,
  Save, 
  AlertTriangle, 
  Eye, 
  EyeOff, 
  Camera,
  ChevronRight,
  ChevronLeft
} from 'lucide-react';
import { Student } from '../types';

interface StudentsViewProps {
  students: Student[];
  onAddStudent: (student: Student) => void;
  onUpdateStudent: (student: Student) => void;
  onDeleteStudent: (studentId: string) => void;
  initialModalOpen?: boolean;
  onCloseInitialModal?: () => void;
}

export const StudentsView: React.FC<StudentsViewProps> = ({
  students,
  onAddStudent,
  onUpdateStudent,
  onDeleteStudent,
  initialModalOpen = false,
  onCloseInitialModal,
}) => {
  // Filtering & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [gradeFilter, setGradeFilter] = useState('all');
  const [sectionFilter, setSectionFilter] = useState('all');

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(initialModalOpen);
  const [modalMode, setModalMode] = useState<'add' | 'edit'>('add');
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);

  // Form fields
  const [fullName, setFullName] = useState('');
  const [grade, setGrade] = useState('');
  const [section, setSection] = useState('');
  const [rfidTag, setRfidTag] = useState('');
  const [parentName, setParentName] = useState('');
  const [parentRelation, setParentRelation] = useState('أب');
  const [parentPhone, setParentPhone] = useState('');
  const [pickupPin, setPickupPin] = useState('');
  const [avatarPreview, setAvatarPreview] = useState<string | undefined>(undefined);
  const [showPin, setShowPin] = useState(false);

  // Delete Dialog State
  const [deleteTarget, setDeleteTarget] = useState<Student | null>(null);

  // Toast
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // Filtered Students
  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchSearch =
        searchQuery.trim() === '' ||
        s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.parentPhone.includes(searchQuery) ||
        s.rfidTag.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.code.includes(searchQuery);

      const matchGrade = gradeFilter === 'all' || s.grade.includes(gradeFilter);
      const matchSection = sectionFilter === 'all' || s.section.includes(sectionFilter);

      return matchSearch && matchGrade && matchSection;
    });
  }, [students, searchQuery, gradeFilter, sectionFilter]);

  const openAddModal = () => {
    setModalMode('add');
    setEditingStudent(null);
    setFullName('');
    setGrade('روضة 1');
    setSection('شعبة أ');
    setRfidTag(generateRandomRfidCode());
    setParentName('');
    setParentRelation('أب');
    setParentPhone('05');
    setPickupPin(Math.floor(1000 + Math.random() * 9000).toString());
    setAvatarPreview(undefined);
    setIsModalOpen(true);
  };

  const openEditModal = (student: Student) => {
    setModalMode('edit');
    setEditingStudent(student);
    setFullName(student.name);
    setGrade(student.grade);
    setSection(student.section);
    setRfidTag(student.rfidTag);
    setParentName(student.parentName);
    setParentRelation(student.parentRelation);
    setParentPhone(student.parentPhone.replace('+966 ', ''));
    setPickupPin(student.pickupPin);
    setAvatarPreview(student.avatarUrl);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    if (onCloseInitialModal) onCloseInitialModal();
  };

  const generateRandomRfidCode = () => {
    const chars = '0123456789ABCDEF';
    let result = '';
    for (let part = 0; part < 3; part++) {
      let segment = '';
      for (let i = 0; i < 4; i++) {
        segment += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      result += (part > 0 ? '-' : '') + segment;
    }
    return result;
  };

  const handleRandomizeRfid = () => {
    setRfidTag(generateRandomRfidCode());
    showToast('تم التقاط كود RFID جديد من الماسح');
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      const reader = new FileReader();
      reader.onload = (event) => {
        setAvatarPreview(event.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName || !grade || !section || !rfidTag || !parentName) return;

    if (modalMode === 'add') {
      const newStudent: Student = {
        id: `STD-2024-${Math.floor(1000 + Math.random() * 9000)}`,
        code: `#0${students.length + 105}`,
        name: fullName,
        grade,
        section,
        rfidTag,
        parentName,
        parentRelation,
        parentPhone: parentPhone.startsWith('+') ? parentPhone : `+966 ${parentPhone}`,
        pickupPin,
        avatarUrl: avatarPreview || 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNgJbjnwPKjAXr32hHmLEcz2dm6dP8gHsmjzhE-Vaw0z7XK9qO0zAkMWBwfjnUQjwoYXUk7Bc8gxlhs12lKCW240QMbte_HGG9FP66Yz-H8OutYV744F0tflSK5PKhhHbymjpu0AtWIyz3Jj-C9qaujMjFRj4G42g2VDo4-JJlGAjTIHf-egLpFF9sVrcxQfyb-Uz3GckdturaG4kmsDFOaFcoWGldlI8YMYfa_v2Con94ttBHsIUKBw',
        enrollmentDate: new Date().toLocaleDateString('en-GB'),
        status: 'present',
      };
      onAddStudent(newStudent);
      showToast('تمت إضافة الطالب الجديد بنجاح');
    } else if (editingStudent) {
      const updated: Student = {
        ...editingStudent,
        name: fullName,
        grade,
        section,
        rfidTag,
        parentName,
        parentRelation,
        parentPhone: parentPhone.startsWith('+') ? parentPhone : `+966 ${parentPhone}`,
        pickupPin,
        avatarUrl: avatarPreview || editingStudent.avatarUrl,
      };
      onUpdateStudent(updated);
      showToast('تم تحديث بيانات الطالب بنجاح');
    }

    closeModal();
  };

  const confirmDelete = () => {
    if (deleteTarget) {
      onDeleteStudent(deleteTarget.id);
      showToast('تم حذف ملف الطالب وسحب الصلاحية بنجاح');
      setDeleteTarget(null);
    }
  };

  return (
    <div className="flex flex-col w-full gap-5 select-none">
      {/* Overview Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Card 1 */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-xs text-[#757682]">إجمالي الطلاب المسجلين</span>
            <span className="text-2xl font-bold text-[#00236f] mt-1">{students.length}</span>
            <span className="text-xs text-[#059669] flex items-center gap-1 mt-1 font-semibold">
              <TrendingUp className="w-3.5 h-3.5" />
              +12 طالب هذا الشهر
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-[#f0f3ff] flex items-center justify-center text-[#00236f]">
            <Users className="w-6 h-6" />
          </div>
        </div>

        {/* Card 2 */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-xs text-[#757682]">بطاقات RFID المفعلة</span>
            <span className="text-2xl font-bold text-[#151c27] mt-1">{students.length}</span>
            <span className="text-xs text-[#059669] flex items-center gap-1 mt-1 font-semibold">
              <CheckCircle2 className="w-3.5 h-3.5" />
              نسبة التغطية 97%
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-[#f0f3ff] flex items-center justify-center text-[#d97706]">
            <Radio className="w-6 h-6" />
          </div>
        </div>

        {/* Card 3 */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-xs text-[#757682]">أولياء الأمور المعتمدين</span>
            <span className="text-2xl font-bold text-[#151c27] mt-1">{students.length}</span>
            <span className="text-xs text-[#00236f] flex items-center gap-1 mt-1 font-semibold">
              <KeyRound className="w-3.5 h-3.5" />
              جميعهم برموز PIN نشطة
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-[#f0f3ff] flex items-center justify-center text-[#1e3a8a]">
            <Users className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Integrated Operational Control Bar */}
      <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3.5">
        <div className="flex flex-col sm:flex-row items-center gap-2.5 flex-1">
          {/* Search Field */}
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-[#757682]" />
            <input
              id="student-search-input"
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="ابحث باسم الطالب، رقم الهوية أو جوال الولي..."
              className="w-full h-10 pr-10 pl-8 rounded-xl bg-[#f0f3ff] text-xs text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute left-2.5 top-1/2 -translate-y-1/2 text-[#757682] hover:text-[#151c27]"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Grade Filter */}
          <div className="relative w-full sm:w-48">
            <select
              id="grade-filter-select"
              value={gradeFilter}
              onChange={(e) => setGradeFilter(e.target.value)}
              className="w-full h-10 px-3 rounded-xl bg-[#f0f3ff] text-xs font-semibold text-[#151c27] focus:outline-none cursor-pointer"
            >
              <option value="all">جميع الصفوف الدراسية</option>
              <option value="روضة 1">الروضة الأولى (KG1)</option>
              <option value="روضة 2">الروضة الثانية (KG2)</option>
              <option value="تمهيدي">التمهيدي (KG3)</option>
              <option value="الصف">المرحلة الابتدائية</option>
            </select>
          </div>

          {/* Section Filter */}
          <div className="relative w-full sm:w-36">
            <select
              id="section-filter-select"
              value={sectionFilter}
              onChange={(e) => setSectionFilter(e.target.value)}
              className="w-full h-10 px-3 rounded-xl bg-[#f0f3ff] text-xs font-semibold text-[#151c27] focus:outline-none cursor-pointer"
            >
              <option value="all">كافة الشُعب</option>
              <option value="شعبة أ">شعبة (أ)</option>
              <option value="شعبة ب">شعبة (ب)</option>
              <option value="شعبة ج">شعبة (ج)</option>
            </select>
          </div>

          {/* Reset button */}
          <button
            id="reset-student-filters"
            onClick={() => {
              setSearchQuery('');
              setGradeFilter('all');
              setSectionFilter('all');
            }}
            title="إعادة ضبط الفلاتر"
            className="h-10 px-3 rounded-xl bg-[#f0f3ff] hover:bg-[#e2e8f8] text-[#444651] flex items-center justify-center transition-colors"
          >
            <FilterX className="w-4 h-4" />
          </button>
        </div>

        {/* Primary Action Button */}
        <div className="flex items-center gap-2 justify-end">
          <button
            id="add-student-modal-trigger"
            onClick={openAddModal}
            className="h-10 px-5 rounded-xl bg-[#1e3a8a] text-white font-bold text-xs hover:bg-[#00236f] transition-all flex items-center gap-2 shadow-xs active:scale-95 shrink-0"
          >
            <UserPlus className="w-4 h-4" />
            <span>إضافة طالب جديد</span>
          </button>
        </div>
      </div>

      {/* Students Data Table Container */}
      <div className="bg-white rounded-2xl shadow-xs border border-[#e2e8f8] overflow-hidden flex flex-col">
        {/* Table Sub-header */}
        <div className="px-5 py-3 bg-[#f0f3ff] flex items-center justify-between border-b border-[#e2e8f8]">
          <div className="flex items-center gap-3">
            <span className="text-xs font-bold text-[#00236f] flex items-center gap-1.5">
              <BadgeHelp className="w-4 h-4 text-[#1e3a8a]" />
              سجلات الطلاب المسجلين
            </span>
            <span className="bg-[#e7eefe] px-2.5 py-0.5 rounded-full text-[11px] text-[#444651] font-bold">
              عرض {filteredStudents.length} من أصل {students.length} طالب
            </span>
          </div>

          <button
            onClick={() => window.print()}
            className="h-8 px-3 rounded-lg text-[#444651] hover:bg-[#e7eefe] hover:text-[#00236f] text-xs font-semibold flex items-center gap-1.5 transition-colors"
          >
            <FileSpreadsheet className="w-4 h-4" />
            <span>تصدير كشف Excel</span>
          </button>
        </div>

        {/* Responsive Table */}
        <div className="w-full overflow-x-auto">
          <table className="w-full text-right border-collapse text-xs">
            <thead>
              <tr className="bg-[#f0f3ff]/50 text-[#444651] font-bold border-b border-[#e2e8f8]">
                <th className="py-3 px-5 w-28">معرف الطالب</th>
                <th className="py-3 px-4">اسم الطالب</th>
                <th className="py-3 px-4">الصف / الشعبة</th>
                <th className="py-3 px-4">رقم بطاقة RFID</th>
                <th className="py-3 px-4">ولي الأمر المسجل</th>
                <th className="py-3 px-4">رقم هاتف التواصل</th>
                <th className="py-3 px-5 text-center w-28">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f0f3ff]">
              {filteredStudents.map((s) => (
                <tr key={s.id} className="hover:bg-[#f0f3ff]/60 transition-colors group">
                  <td className="py-3 px-5 font-mono text-[#757682] font-semibold">
                    {s.code}
                  </td>
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-2.5">
                      {s.avatarUrl ? (
                        <img
                          src={s.avatarUrl}
                          alt={s.name}
                          className="w-9 h-9 rounded-full object-cover shadow-xs ring-1 ring-[#e2e8f8]"
                        />
                      ) : (
                        <div className="w-9 h-9 rounded-full bg-[#fef3c7] text-[#92400e] font-bold flex items-center justify-center text-sm shadow-xs">
                          {s.name.charAt(0)}
                        </div>
                      )}
                      <div className="flex flex-col">
                        <span className="font-bold text-[#151c27] group-hover:text-[#00236f] transition-colors">
                          {s.name}
                        </span>
                        <span className="text-[10px] text-[#757682]">
                          تاريخ الانضمام: {s.enrollmentDate}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-4">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] bg-[#f0f3ff] text-[#00236f] font-semibold border border-[#e2e8f8]">
                      {s.grade} - {s.section}
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    <div className="inline-flex items-center gap-1.5 bg-[#f0f3ff] px-2.5 py-1 rounded-lg border border-[#e2e8f8]">
                      <Radio className="w-3.5 h-3.5 text-[#059669]" />
                      <span className="font-mono text-[11px] font-bold text-[#444651]">
                        {s.rfidTag}
                      </span>
                    </div>
                  </td>
                  <td className="py-3 px-4">
                    <div className="flex flex-col">
                      <span className="font-semibold text-[#151c27]">{s.parentName}</span>
                      <span className="text-[10px] text-[#757682]">الصلة: {s.parentRelation}</span>
                    </div>
                  </td>
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-1 text-[#444651] font-mono" dir="ltr">
                      <Phone className="w-3.5 h-3.5 text-[#757682]" />
                      <span>{s.parentPhone}</span>
                    </div>
                  </td>
                  <td className="py-3 px-5 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button
                        onClick={() => openEditModal(s)}
                        className="w-7 h-7 rounded-lg flex items-center justify-center text-[#1e3a8a] hover:bg-[#e7eefe] transition-colors"
                        title="تعديل بيانات الطالب"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setDeleteTarget(s)}
                        className="w-7 h-7 rounded-lg flex items-center justify-center text-[#ef4444] hover:bg-[#fee2e2] transition-colors"
                        title="حذف الطالب"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Table Footer */}
        <div className="px-5 py-3 bg-white border-t border-[#e2e8f8] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-[#757682]">
          <div>
            <span>عرض الصفوف: </span>
            <span className="font-bold text-[#151c27]">10 صفوف</span>
            <span className="mr-3">الصفحة 1 من 1</span>
          </div>
          <div className="flex items-center gap-1">
            <button className="w-7 h-7 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#f0f3ff] transition-colors">
              <ChevronRight className="w-4 h-4" />
            </button>
            <button className="w-7 h-7 rounded-lg bg-[#1e3a8a] text-white font-bold">1</button>
            <button className="w-7 h-7 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#f0f3ff] transition-colors">
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* MODAL: Add / Edit Student Form */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4 animate-in fade-in">
          <div className="bg-white w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            {/* Header */}
            <div className="px-6 py-4 bg-[#f0f3ff] border-b border-[#e2e8f8] flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#1e3a8a] text-white flex items-center justify-center">
                  <UserPlus className="w-5 h-5" />
                </div>
                <div className="flex flex-col">
                  <h3 className="text-base font-bold text-[#00236f]">
                    {modalMode === 'add' ? 'إضافة طالب جديد' : 'تعديل بيانات الطالب'}
                  </h3>
                  <span className="text-xs text-[#757682]">
                    تسجيل بيانات الطفل وربط بطاقة الحضور وولي الأمر
                  </span>
                </div>
              </div>
              <button
                onClick={closeModal}
                className="w-8 h-8 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#e2e8f8]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form Body */}
            <form onSubmit={handleSubmit} className="overflow-y-auto p-6 flex flex-col gap-6 text-xs">
              {/* SECTION 1: Student Information */}
              <div className="flex flex-col gap-4">
                <div className="flex items-center justify-between pb-1 border-b border-[#f0f3ff]">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#1e3a8a]"></span>
                    <h4 className="text-sm font-bold text-[#151c27]">
                      القسم الأول: بيانات الطالب الأكاديمية
                    </h4>
                  </div>
                  <span className="text-[11px] text-[#757682]">حقول إلزامية *</span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-start">
                  {/* Photo upload column */}
                  <div className="md:col-span-3 flex flex-col items-center gap-2">
                    <div className="relative group cursor-pointer w-24 h-24 rounded-full bg-[#f0f3ff] border-2 border-dashed border-[#c5c5d3] flex items-center justify-center overflow-hidden">
                      {avatarPreview ? (
                        <img
                          src={avatarPreview}
                          alt="Student Preview"
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="flex flex-col items-center justify-center text-[#757682]">
                          <Camera className="w-6 h-6" />
                          <span className="text-[10px] mt-1 font-semibold">صورة الطالب</span>
                        </div>
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleAvatarChange}
                        className="absolute inset-0 opacity-0 cursor-pointer"
                      />
                    </div>
                    <span className="text-[10px] text-[#757682] text-center">اختياري (JPG/PNG)</span>
                  </div>

                  {/* Inputs column */}
                  <div className="md:col-span-9 grid grid-cols-1 md:grid-cols-2 gap-3.5">
                    <div className="md:col-span-2 flex flex-col gap-1.5">
                      <label className="font-bold text-[#151c27]">
                        اسم الطالب الثلاثي <span className="text-[#ef4444]">*</span>
                      </label>
                      <input
                        type="text"
                        required
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        placeholder="مثال: ريان فهد الحارثي"
                        className="h-10 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none"
                      />
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label className="font-bold text-[#151c27]">
                        المرحلة / الصف <span className="text-[#ef4444]">*</span>
                      </label>
                      <select
                        value={grade}
                        onChange={(e) => setGrade(e.target.value)}
                        className="h-10 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:outline-none cursor-pointer"
                      >
                        <option value="روضة 1">الروضة الأولى (KG1)</option>
                        <option value="روضة 2">الروضة الثانية (KG2)</option>
                        <option value="تمهيدي">التمهيدي (KG3)</option>
                        <option value="الصف الأول الابتدائي">الصف الأول الابتدائي</option>
                        <option value="الصف الثاني الابتدائي">الصف الثاني الابتدائي</option>
                        <option value="الصف الثالث الابتدائي">الصف الثالث الابتدائي</option>
                        <option value="الصف الرابع الابتدائي">الصف الرابع الابتدائي</option>
                        <option value="الصف الخامس الابتدائي">الصف الخامس الابتدائي</option>
                        <option value="الصف السادس الابتدائي">الصف السادس الابتدائي</option>
                      </select>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label className="font-bold text-[#151c27]">
                        الشعبة الدراسية <span className="text-[#ef4444]">*</span>
                      </label>
                      <select
                        value={section}
                        onChange={(e) => setSection(e.target.value)}
                        className="h-10 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:outline-none cursor-pointer"
                      >
                        <option value="شعبة أ">شعبة (أ)</option>
                        <option value="شعبة ب">شعبة (ب)</option>
                        <option value="شعبة ج">شعبة (ج)</option>
                      </select>
                    </div>

                    {/* RFID Tag with Auto-Generator */}
                    <div className="md:col-span-2 flex flex-col gap-1.5">
                      <div className="flex items-center justify-between">
                        <label className="font-bold text-[#151c27] flex items-center gap-1">
                          <Radio className="w-3.5 h-3.5 text-[#059669]" />
                          معرف بطاقة الحضور الذكية (RFID Tag) <span className="text-[#ef4444]">*</span>
                        </label>
                        <span className="text-[11px] text-[#059669] font-bold flex items-center gap-1">
                          <span className="w-2 h-2 rounded-full bg-[#10b981] animate-ping"></span>
                          جاهز للمسح عبر USB Scanner
                        </span>
                      </div>
                      <div className="relative">
                        <input
                          type="text"
                          required
                          value={rfidTag}
                          onChange={(e) => setRfidTag(e.target.value)}
                          placeholder="مرر البطاقة أو أدخل الكود..."
                          className="w-full h-10 pr-4 pl-24 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] font-mono text-xs font-bold text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none"
                        />
                        <button
                          type="button"
                          onClick={handleRandomizeRfid}
                          className="absolute left-2 top-1/2 -translate-y-1/2 px-2.5 py-1 rounded-lg bg-[#e7eefe] text-[#00236f] font-bold text-[11px] hover:bg-[#dce2f3]"
                        >
                          توليد عشوائي
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* SECTION 2: Parent & Guardian */}
              <div className="flex flex-col gap-4 pt-2 border-t border-[#f0f3ff]">
                <div className="flex items-center justify-between pb-1 border-b border-[#f0f3ff]">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#fea619]"></span>
                    <h4 className="text-sm font-bold text-[#151c27]">
                      القسم الثاني: بيانات ولي الأمر وبوابة الاستلام
                    </h4>
                  </div>
                  <span className="text-[11px] text-[#757682]">تأكيد أمني للاستئذان</span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
                  <div className="flex flex-col gap-1.5">
                    <label className="font-bold text-[#151c27]">
                      اسم ولي الأمر المعتمد <span className="text-[#ef4444]">*</span>
                    </label>
                    <input
                      type="text"
                      required
                      value={parentName}
                      onChange={(e) => setParentName(e.target.value)}
                      placeholder="مثال: فهد عبد الله الحارثي"
                      className="h-10 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none"
                    />
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="font-bold text-[#151c27]">
                      رقم جوال ولي الأمر (واتساب / إشعارات) <span className="text-[#ef4444]">*</span>
                    </label>
                    <input
                      type="tel"
                      required
                      dir="ltr"
                      value={parentPhone}
                      onChange={(e) => setParentPhone(e.target.value)}
                      placeholder="05XXXXXXXX"
                      className="h-10 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] font-mono text-left focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none"
                    />
                  </div>

                  {/* Security PIN for Pickup */}
                  <div className="md:col-span-2 flex flex-col gap-1.5">
                    <div className="flex items-center justify-between">
                      <label className="font-bold text-[#151c27] flex items-center gap-1.5">
                        <KeyRound className="w-3.5 h-3.5 text-[#fea619]" />
                        رمز PIN السري المخصص للاستلام من البوابة (4 أرقام) <span className="text-[#ef4444]">*</span>
                      </label>
                      <span className="text-[11px] text-[#757682]">يُستخدم للتحقق عند المناداة</span>
                    </div>
                    <div className="relative max-w-xs">
                      <input
                        type={showPin ? 'text' : 'password'}
                        maxLength={4}
                        required
                        value={pickupPin}
                        onChange={(e) => setPickupPin(e.target.value)}
                        className="w-full h-10 px-4 pl-12 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] font-mono text-center text-sm font-bold tracking-widest focus:bg-white focus:outline-none"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPin(!showPin)}
                        className="absolute left-2.5 top-1/2 -translate-y-1/2 text-[#757682] hover:text-[#151c27] p-1"
                      >
                        {showPin ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center justify-end gap-2.5 pt-4 border-t border-[#f0f3ff]">
                <button
                  type="button"
                  onClick={closeModal}
                  className="px-5 h-10 rounded-xl bg-[#f0f3ff] text-[#444651] font-bold hover:bg-[#e2e8f8] transition-colors"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 h-10 rounded-xl bg-[#1e3a8a] text-white font-bold hover:bg-[#00236f] transition-all flex items-center gap-2 shadow-xs active:scale-95"
                >
                  <Save className="w-4 h-4" />
                  <span>{modalMode === 'add' ? 'حفظ بيانات الطالب' : 'تحديث التعديلات'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* DANGER CONFIRMATION MODAL */}
      {deleteTarget && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4 animate-in fade-in">
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl p-6 flex flex-col items-center text-center">
            <div className="w-16 h-16 rounded-full bg-[#fee2e2] text-[#ef4444] flex items-center justify-center mb-4">
              <AlertTriangle className="w-8 h-8" />
            </div>
            <h3 className="text-base font-bold text-[#151c27] mb-1">
              تأكيد حذف سجل الطالب
            </h3>
            <p className="text-xs text-[#444651] mb-5 leading-relaxed">
              هل أنت متأكد تماماً من رغبتك في حذف ملف الطالب{' '}
              <span className="font-bold text-[#ef4444]">"{deleteTarget.name}"</span>؟
              <br />
              <span className="text-[11px] text-[#757682] mt-1 block">
                سيؤدي هذا الإجراء إلى إلغاء ربط بطاقة RFID وسحب الصلاحية فورياً.
              </span>
            </p>
            <div className="flex items-center gap-3 w-full">
              <button
                onClick={() => setDeleteTarget(null)}
                className="flex-1 h-10 rounded-xl bg-[#f0f3ff] text-[#444651] font-bold hover:bg-[#e2e8f8] text-xs transition-colors"
              >
                تراجع
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 h-10 rounded-xl bg-[#ef4444] text-white font-bold hover:bg-[#dc2626] text-xs transition-all flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Trash2 className="w-4 h-4" />
                <span>نعم، احذف الطالب</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 left-6 z-50 bg-[#2a313d] text-white px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5">
          <CheckCircle2 className="w-5 h-5 text-[#27c38a]" />
          <span className="text-xs font-bold">{toastMessage}</span>
        </div>
      )}
    </div>
  );
};
