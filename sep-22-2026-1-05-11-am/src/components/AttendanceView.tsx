import React, { useState, useMemo } from 'react';
import { 
  UserCheck, 
  UserX, 
  Clock, 
  Fingerprint, 
  Calendar, 
  ChevronRight, 
  ChevronLeft, 
  PlusCircle, 
  Search, 
  Check, 
  X, 
  MoreVertical, 
  Paperclip, 
  Eye, 
  UploadCloud,
  FileCheck2,
  CalendarDays
} from 'lucide-react';
import { AttendanceRecord, Student } from '../types';

interface AttendanceViewProps {
  records: AttendanceRecord[];
  students: Student[];
  onAddLeave: (record: AttendanceRecord) => void;
  initialLeaveModalOpen?: boolean;
  onCloseInitialLeaveModal?: () => void;
}

export const AttendanceView: React.FC<AttendanceViewProps> = ({
  records,
  students,
  onAddLeave,
  initialLeaveModalOpen = false,
  onCloseInitialLeaveModal,
}) => {
  // Date State
  const dateOptions = [
    'الإثنين، 12 رجب 1446هـ',
    'الثلاثاء، 13 رجب 1446هـ',
    'الأربعاء، 14 رجب 1446هـ',
    'الخميس، 15 رجب 1446هـ'
  ];
  const [dateIndex, setDateIndex] = useState(1); // Tuesday

  // Filter Pill
  const [activePill, setActivePill] = useState<'all' | 'present' | 'absent' | 'excused'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Modal State
  const [isLeaveModalOpen, setIsLeaveModalOpen] = useState(initialLeaveModalOpen);
  const [selectedStudentName, setSelectedStudentName] = useState('');
  const [leaveStartDate, setLeaveStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [leaveType, setLeaveType] = useState('مرضي');
  const [leaveReason, setLeaveReason] = useState('');
  const [attachedFileName, setAttachedFileName] = useState<string | null>(null);

  // Toasts
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [excelToast, setExcelToast] = useState(false);

  // Student search in modal
  const [showStudentDropdown, setShowStudentDropdown] = useState(false);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const filteredRecords = useMemo(() => {
    return records.filter((r) => {
      const matchPill = activePill === 'all' || r.status === activePill;
      const matchSearch =
        searchQuery.trim() === '' ||
        r.studentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        r.grade.toLowerCase().includes(searchQuery.toLowerCase()) ||
        r.notes.toLowerCase().includes(searchQuery.toLowerCase());
      return matchPill && matchSearch;
    });
  }, [records, activePill, searchQuery]);

  const handleOpenLeaveModal = (prefillStudent = '') => {
    setSelectedStudentName(prefillStudent);
    setLeaveStartDate(new Date().toISOString().split('T')[0]);
    setLeaveType('مرضي');
    setLeaveReason(prefillStudent ? 'مراجعة عيادة طبية لعارض صحي' : '');
    setAttachedFileName(null);
    setIsLeaveModalOpen(true);
  };

  const handleCloseLeaveModal = () => {
    setIsLeaveModalOpen(false);
    if (onCloseInitialLeaveModal) onCloseInitialLeaveModal();
  };

  const handleLeaveSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStudentName || !leaveReason) return;

    const matched = students.find((s) => s.name === selectedStudentName);

    const newRec: AttendanceRecord = {
      id: `ATT-${Date.now()}`,
      studentId: matched ? matched.id : 'STD-NEW',
      studentName: selectedStudentName,
      grade: matched ? `${matched.grade} - ${matched.section}` : 'الصف العام',
      section: matched ? matched.section : 'أ',
      time: `مسبقاً (${new Date().toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' })})`,
      date: leaveStartDate,
      status: 'excused',
      notes: `عذر ${leaveType}: ${leaveReason}`,
      excuseType: leaveType,
      avatarUrl: matched?.avatarUrl,
    };

    onAddLeave(newRec);
    handleCloseLeaveModal();
    showToast('تم تسجيل الإجازة بنجاح وتحديث كشف الحضور');
  };

  const handleExportExcel = () => {
    setExcelToast(true);
    setTimeout(() => setExcelToast(false), 3500);

    // Generate CSV data for download
    const headers = ['وقت التسجيل', 'اسم الطالب', 'الصف', 'الحالة', 'الملاحظات'];
    const rows = filteredRecords.map(r => [
      r.time,
      r.studentName,
      r.grade,
      r.status === 'present' ? 'حاضر' : r.status === 'absent' ? 'غائب' : 'مجاز',
      r.notes
    ]);
    const csvContent = "data:text/csv;charset=utf-8,\uFEFF" + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `تقرير_الحضور_${dateOptions[dateIndex].replace(/\s+/g, '_')}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="flex flex-col w-full gap-5 select-none">
      {/* Top KPI Highlights */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3.5">
        {/* Present Students */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#ecfdf5] text-[#059669] flex items-center justify-center">
              <UserCheck className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">الطلاب الحاضرون</span>
              <div className="flex items-baseline gap-1 mt-0.5">
                <span className="text-2xl font-bold text-[#151c27]">1,142</span>
                <span className="text-xs font-bold text-[#059669]">92.8%</span>
              </div>
            </div>
          </div>
          {/* Circular progress SVG */}
          <div className="w-10 h-10">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
              <path
                className="text-[#f0f3ff]"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                fill="none"
                stroke="currentColor"
                strokeWidth="3.5"
              />
              <path
                className="text-[#10b981]"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                fill="none"
                stroke="currentColor"
                strokeDasharray="92.8, 100"
                strokeLinecap="round"
                strokeWidth="3.5"
              />
            </svg>
          </div>
        </div>

        {/* Absent Students */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#fee2e2] text-[#dc2626] flex items-center justify-center">
              <UserX className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">الغياب غير المبرر</span>
              <div className="flex items-baseline gap-1 mt-0.5">
                <span className="text-2xl font-bold text-[#151c27]">48</span>
                <span className="text-xs font-bold text-[#dc2626]">3.9%</span>
              </div>
            </div>
          </div>
          <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#fee2e2] text-[#dc2626] font-bold border border-[#fecaca]">
            يحتاج متابعة
          </span>
        </div>

        {/* Approved Leaves */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#fef3c7] text-[#b45309] flex items-center justify-center">
              <Clock className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">إجازات واستئذان معتمد</span>
              <div className="flex items-baseline gap-1 mt-0.5">
                <span className="text-2xl font-bold text-[#151c27]">39</span>
                <span className="text-xs font-bold text-[#b45309]">3.3%</span>
              </div>
            </div>
          </div>
          <div className="flex -space-x-1.5 space-x-reverse overflow-hidden">
            <img
              className="inline-block h-6 w-6 rounded-full ring-2 ring-white object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuBNgJbjnwPKjAXr32hHmLEcz2dm6dP8gHsmjzhE-Vaw0z7XK9qO0zAkMWBwfjnUQjwoYXUk7Bc8gxlhs12lKCW240QMbte_HGG9FP66Yz-H8OutYV744F0tflSK5PKhhHbymjpu0AtWIyz3Jj-C9qaujMjFRj4G42g2VDo4-JJlGAjTIHf-egLpFF9sVrcxQfyb-Uz3GckdturaG4kmsDFOaFcoWGldlI8YMYfa_v2Con94ttBHsIUKBw"
              alt="طالب"
            />
            <img
              className="inline-block h-6 w-6 rounded-full ring-2 ring-white object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCG8Y28AqGpv1L3kOPoXldsxo-IXpJUfLp-AO2zVNK-0J993DB566BOEoal9Hf_Dzn8g86XH49eGxmDac9KkCAu4Xt2N1fUiT2oVD_5pynCwsA4_5iL_iVduRXfL_OBBILVFJoU3oXHiykxIlUxDgf6IvUqsMr0DkVKDgdzQ26Mh2KWDLAKqc5-N3WAis1pkcwVCsPbt-DpgP8bP2B-iue8DkIUlEQdNQPdgf0_q6vXhzLtmYOGeQiE_Q"
              alt="طالبة"
            />
            <span className="inline-flex items-center justify-center h-6 w-6 rounded-full bg-[#f0f3ff] text-[#444651] text-[9px] font-bold border border-[#e2e8f8]">
              +37
            </span>
          </div>
        </div>

        {/* Active Gateways */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#e7eefe] text-[#1e3a8a] flex items-center justify-center">
              <Fingerprint className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">جهاز الحضور الذكي</span>
              <div className="flex items-baseline gap-1 mt-0.5">
                <span className="text-sm font-bold text-[#151c27]">متصل ونشط</span>
                <span className="text-[11px] font-bold text-[#059669]">رئيسي</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#10b981] animate-pulse"></span>
            <span className="text-xs text-[#757682] font-semibold">مباشر</span>
          </div>
        </div>
      </div>

      {/* Main Operational Surface */}
      <div className="bg-white rounded-2xl shadow-xs border border-[#e2e8f8] flex flex-col overflow-hidden">
        {/* Specialized Master Toolbar */}
        <div className="p-4 md:p-5 flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4 border-b border-[#e2e8f8]">
          {/* Right side: Date Navigation & Day Switcher */}
          <div className="flex items-center gap-2.5 flex-wrap">
            <div className="flex items-center bg-[#f0f3ff] rounded-xl p-1 border border-[#e2e8f8]">
              <button
                onClick={() => setDateIndex((prev) => Math.max(0, prev - 1))}
                disabled={dateIndex === 0}
                className="w-8 h-8 flex items-center justify-center rounded-lg text-[#444651] hover:bg-white hover:text-[#151c27] transition-all disabled:opacity-40"
                title="اليوم السابق"
              >
                <ChevronRight className="w-4 h-4" />
              </button>

              <div className="flex items-center gap-2 px-3 py-1">
                <Calendar className="w-4 h-4 text-[#00236f]" />
                <span className="text-xs font-bold text-[#151c27]">
                  {dateOptions[dateIndex]}
                </span>
                <span className="text-[11px] text-[#757682] hidden sm:inline">(اليوم)</span>
              </div>

              <button
                onClick={() => setDateIndex((prev) => Math.min(dateOptions.length - 1, prev + 1))}
                disabled={dateIndex === dateOptions.length - 1}
                className="w-8 h-8 flex items-center justify-center rounded-lg text-[#444651] hover:bg-white hover:text-[#151c27] transition-all disabled:opacity-40"
                title="اليوم التالي"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>

            {/* Quick Today Shortcut */}
            <button
              onClick={() => setDateIndex(1)}
              className="px-4 h-10 rounded-xl bg-[#f0f3ff] text-[#00236f] text-xs font-bold hover:bg-[#e2e8f8] transition-all border border-[#e2e8f8]"
            >
              اليوم
            </button>

            {/* Filter Pills */}
            <div className="flex items-center gap-1 bg-[#f0f3ff] p-1 rounded-xl border border-[#e2e8f8]">
              <button
                onClick={() => setActivePill('all')}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  activePill === 'all'
                    ? 'bg-[#1e3a8a] text-white shadow-xs'
                    : 'text-[#444651] hover:text-[#151c27]'
                }`}
              >
                الكل ({records.length})
              </button>
              <button
                onClick={() => setActivePill('present')}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  activePill === 'present'
                    ? 'bg-[#1e3a8a] text-white shadow-xs'
                    : 'text-[#444651] hover:text-[#151c27]'
                }`}
              >
                الحاضرون (1,142)
              </button>
              <button
                onClick={() => setActivePill('absent')}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  activePill === 'absent'
                    ? 'bg-[#1e3a8a] text-white shadow-xs'
                    : 'text-[#444651] hover:text-[#151c27]'
                }`}
              >
                الغياب (48)
              </button>
              <button
                onClick={() => setActivePill('excused')}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  activePill === 'excused'
                    ? 'bg-[#1e3a8a] text-white shadow-xs'
                    : 'text-[#444651] hover:text-[#151c27]'
                }`}
              >
                الإجازات (39)
              </button>
            </div>
          </div>

          {/* Left side: Actions (Grant Leave + Excel Export) */}
          <div className="flex items-center gap-2.5 justify-end flex-wrap">
            {/* Grant Leave Modal Trigger */}
            <button
              id="grant-leave-button"
              onClick={() => handleOpenLeaveModal()}
              className="h-10 px-4 rounded-xl bg-[#fea619] text-[#684000] text-xs font-bold flex items-center gap-2 shadow-xs hover:brightness-105 active:scale-95 transition-all"
            >
              <PlusCircle className="w-4 h-4" />
              <span>منح إجازة</span>
            </button>

            {/* Official Excel App Icon Export Button */}
            <button
              id="excel-export-button"
              onClick={handleExportExcel}
              className="h-10 px-4 rounded-xl bg-white text-[#004a31] text-xs font-bold flex items-center gap-2 shadow-xs border border-[#e2e8f8] hover:bg-[#f0f3ff] active:scale-95 transition-all"
            >
              <svg className="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M14.5 2H6C4.89543 2 4 2.89543 4 4V20C4 21.1046 4.89543 22 6 22H18C19.1046 22 20 21.1046 20 20V7.5L14.5 2Z" fill="#107C41" />
                <path d="M14 2V8H20" fill="#33C481" />
                <path d="M14.5 2L20 7.5H14.5V2Z" fill="#185C37" />
                <path d="M7 11.5L9.5 15.5L7 19.5H9L10.5 17L12 19.5H14L11.5 15.5L14 11.5H12L10.5 14L9 11.5H7Z" fill="white" />
              </svg>
              <span>تصدير إلى Excel</span>
            </button>
          </div>
        </div>

        {/* Search Sub-bar */}
        <div className="px-5 py-3 bg-[#f0f3ff]/50 border-b border-[#e2e8f8] flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="relative w-full md:w-96">
            <Search className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-[#757682]" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="بحث باسم الطالب، الصف، أو رقم الهوية..."
              className="w-full h-10 pr-10 pl-4 bg-white rounded-xl text-xs text-[#151c27] focus:outline-none focus:ring-2 focus:ring-[#1e3a8a] shadow-xs border border-[#e2e8f8]"
            />
          </div>
          <div className="flex items-center gap-2 text-xs text-[#444651]">
            <span className="w-2 h-2 rounded-full bg-[#10b981] animate-ping"></span>
            <span>البث متزامن مع بوابات الحضور</span>
          </div>
        </div>

        {/* Real-time Attendance Records Table */}
        <div className="overflow-x-auto w-full">
          <table className="w-full text-right border-collapse text-xs">
            <thead>
              <tr className="bg-[#f0f3ff] text-[#444651] font-bold border-b border-[#e2e8f8]">
                <th className="py-3 px-5">وقت التسجيل</th>
                <th className="py-3 px-5">الطالب والصف</th>
                <th className="py-3 px-5">حالة الحضور</th>
                <th className="py-3 px-5">الملاحظات / سبب الإجازة</th>
                <th className="py-3 px-5 text-left">إجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f0f3ff]">
              {filteredRecords.map((item) => (
                <tr key={item.id} className="hover:bg-[#f0f3ff]/60 transition-colors group">
                  <td className="py-3 px-5 text-[#151c27] font-semibold whitespace-nowrap">
                    <span className="font-mono text-[11px]">{item.time}</span>
                  </td>
                  <td className="py-3 px-5">
                    <div className="flex items-center gap-3">
                      <img
                        src={item.avatarUrl || 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNgJbjnwPKjAXr32hHmLEcz2dm6dP8gHsmjzhE-Vaw0z7XK9qO0zAkMWBwfjnUQjwoYXUk7Bc8gxlhs12lKCW240QMbte_HGG9FP66Yz-H8OutYV744F0tflSK5PKhhHbymjpu0AtWIyz3Jj-C9qaujMjFRj4G42g2VDo4-JJlGAjTIHf-egLpFF9sVrcxQfyb-Uz3GckdturaG4kmsDFOaFcoWGldlI8YMYfa_v2Con94ttBHsIUKBw'}
                        alt={item.studentName}
                        className="w-10 h-10 rounded-xl object-cover shadow-xs ring-1 ring-[#e2e8f8]"
                      />
                      <div className="flex flex-col">
                        <span className="font-bold text-[#151c27] group-hover:text-[#00236f] transition-colors">
                          {item.studentName}
                        </span>
                        <span className="text-[11px] text-[#757682]">{item.grade}</span>
                      </div>
                    </div>
                  </td>

                  {/* Status Capsule matching Screen 3 color spec */}
                  <td className="py-3 px-5 whitespace-nowrap">
                    {item.status === 'present' && (
                      <span
                        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-bold text-white shadow-xs"
                        style={{ backgroundColor: '#10B981' }}
                      >
                        <Check className="w-3.5 h-3.5" />
                        <span>حاضر</span>
                      </span>
                    )}
                    {item.status === 'absent' && (
                      <span
                        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-bold text-white shadow-xs"
                        style={{ backgroundColor: '#EF4444' }}
                      >
                        <X className="w-3.5 h-3.5" />
                        <span>غائب</span>
                      </span>
                    )}
                    {item.status === 'excused' && (
                      <span
                        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-bold text-white shadow-xs"
                        style={{ backgroundColor: '#F59E0B' }}
                      >
                        <Clock className="w-3.5 h-3.5" />
                        <span>مجاز</span>
                      </span>
                    )}
                  </td>

                  {/* Notes / Excuse */}
                  <td className="py-3 px-5 text-[#444651]">
                    {item.status === 'absent' ? (
                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#fee2e2] text-[#dc2626] font-semibold">
                        <span>{item.notes}</span>
                      </div>
                    ) : item.status === 'excused' ? (
                      <div className="flex items-center gap-1.5 text-[#151c27]">
                        <span className="w-2 h-2 rounded-full bg-[#fea619]"></span>
                        <span className="font-semibold">{item.notes}</span>
                      </div>
                    ) : (
                      <span className="text-[#757682]">{item.notes}</span>
                    )}
                  </td>

                  {/* Action */}
                  <td className="py-3 px-5 text-left whitespace-nowrap">
                    {item.status === 'absent' ? (
                      <button
                        onClick={() => handleOpenLeaveModal(item.studentName)}
                        className="px-3 py-1 rounded-lg bg-[#f0f3ff] text-[#00236f] font-bold hover:bg-[#1e3a8a] hover:text-white transition-colors"
                      >
                        تسجيل عذر
                      </button>
                    ) : item.status === 'excused' ? (
                      <button
                        onClick={() => showToast(`عرض تفاصيل العذر: ${item.notes}`)}
                        className="w-8 h-8 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#f0f3ff] transition-colors"
                        title="عرض المرفق"
                      >
                        <Paperclip className="w-4 h-4" />
                      </button>
                    ) : (
                      <button className="w-8 h-8 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#f0f3ff]">
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Table Footer */}
        <div className="px-5 py-3.5 bg-[#f0f3ff] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-[#757682] border-t border-[#e2e8f8]">
          <span>
            عرض <b className="text-[#151c27]">1 إلى {filteredRecords.length}</b> من إجمالي{' '}
            <b className="text-[#151c27]">1,229</b> طالب مسجل
          </span>
          <div className="flex items-center gap-1">
            <button className="w-7 h-7 rounded-lg flex items-center justify-center text-[#757682] bg-white border border-[#e2e8f8]">
              <ChevronRight className="w-4 h-4" />
            </button>
            <button className="w-7 h-7 rounded-lg bg-[#1e3a8a] text-white font-bold">1</button>
            <button className="w-7 h-7 rounded-lg bg-white text-[#151c27] hover:bg-[#e7eefe]">2</button>
            <button className="w-7 h-7 rounded-lg bg-white text-[#151c27] hover:bg-[#e7eefe]">3</button>
            <span className="px-1 text-[#757682]">...</span>
            <button className="w-7 h-7 rounded-lg bg-white text-[#151c27] hover:bg-[#e7eefe]">205</button>
            <button className="w-7 h-7 rounded-lg flex items-center justify-center text-[#757682] bg-white border border-[#e2e8f8]">
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* MODAL: Grant Leave to Student */}
      {isLeaveModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden animate-in zoom-in-95">
            {/* Header */}
            <div className="px-6 py-4 bg-[#f0f3ff] border-b border-[#e2e8f8] flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#fef3c7] text-[#b45309] flex items-center justify-center">
                  <PlusCircle className="w-5 h-5" />
                </div>
                <div className="flex flex-col">
                  <h3 className="text-base font-bold text-[#151c27]">منح إجازة أو تسجيل عذر</h3>
                  <span className="text-xs text-[#757682]">
                    تسجيل إجازة مسبقة أو تبرير غياب في السجلات
                  </span>
                </div>
              </div>
              <button
                onClick={handleCloseLeaveModal}
                className="w-8 h-8 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#e2e8f8]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleLeaveSubmit} className="p-6 flex flex-col gap-4 text-xs">
              {/* Student Picker */}
              <div className="flex flex-col gap-1.5 relative">
                <label className="font-bold text-[#151c27] flex items-center justify-between">
                  <span>اختيار الطالب المستفيد <span className="text-[#ef4444]">*</span></span>
                  <span className="text-[11px] text-[#757682]">ابحث بالاسم أو الهوية</span>
                </label>
                <div className="relative">
                  <Search className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-[#757682]" />
                  <input
                    type="text"
                    required
                    value={selectedStudentName}
                    onFocus={() => setShowStudentDropdown(true)}
                    onChange={(e) => {
                      setSelectedStudentName(e.target.value);
                      setShowStudentDropdown(true);
                    }}
                    placeholder="اكتب اسم الطالب للبحث..."
                    className="w-full h-11 pr-10 pl-4 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none"
                  />
                </div>

                {/* Dropdown suggestions */}
                {showStudentDropdown && (
                  <div className="absolute top-full right-0 left-0 mt-1 bg-white rounded-xl shadow-xl z-30 max-h-48 overflow-y-auto border border-[#e2e8f8]">
                    {students
                      .filter((s) => s.name.includes(selectedStudentName))
                      .map((s) => (
                        <div
                          key={s.id}
                          onClick={() => {
                            setSelectedStudentName(s.name);
                            setShowStudentDropdown(false);
                          }}
                          className="p-2.5 hover:bg-[#f0f3ff] cursor-pointer flex items-center justify-between border-b border-[#f0f3ff] last:border-none"
                        >
                          <span className="font-bold text-[#151c27]">{s.name}</span>
                          <span className="text-[11px] text-[#757682]">
                            {s.grade} - {s.section}
                          </span>
                        </div>
                      ))}
                  </div>
                )}
              </div>

              {/* Date & Type */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                <div className="flex flex-col gap-1.5">
                  <label className="font-bold text-[#151c27]">
                    تاريخ بدء الإجازة <span className="text-[#ef4444]">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={leaveStartDate}
                    onChange={(e) => setLeaveStartDate(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:outline-none"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="font-bold text-[#151c27]">نوع العذر</label>
                  <select
                    value={leaveType}
                    onChange={(e) => setLeaveType(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:outline-none cursor-pointer"
                  >
                    <option value="مرضي">عذر مرضي (مستشفى / عيادة)</option>
                    <option value="أسري">عذر أسري طارئ</option>
                    <option value="سفر">سفر مع الأسرة</option>
                    <option value="أخرى">أسباب أخرى خاصة</option>
                  </select>
                </div>
              </div>

              {/* Notes */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27] flex items-center justify-between">
                  <span>تفاصيل وملاحظات الإجازة <span className="text-[#ef4444]">*</span></span>
                  <span className="text-[11px] text-[#757682]">توضيح السبب للاعتماد</span>
                </label>
                <textarea
                  rows={3}
                  required
                  value={leaveReason}
                  onChange={(e) => setLeaveReason(e.target.value)}
                  placeholder="اكتب تفاصيل العذر هنا (مثال: موعد كشف طبي في مستشفى الأطفال، إلخ)..."
                  className="w-full p-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-[#151c27] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none resize-none"
                />
              </div>

              {/* Attachment */}
              <div className="p-3 bg-[#f0f3ff] rounded-xl flex items-center justify-between border border-[#e2e8f8]">
                <div className="flex items-center gap-2 text-[#444651]">
                  <Paperclip className="w-4 h-4 text-[#757682]" />
                  <span>
                    {attachedFileName ? `المرفق: ${attachedFileName}` : 'إرفاق تقرير طبي أو مستند داعم (اختياري)'}
                  </span>
                </div>
                <label className="px-3 py-1 rounded-lg bg-white border border-[#e2e8f8] text-[#00236f] font-bold cursor-pointer hover:bg-gray-50">
                  <span>{attachedFileName ? 'تغيير' : 'رفع ملف'}</span>
                  <input
                    type="file"
                    className="hidden"
                    onChange={(e) => {
                      if (e.target.files && e.target.files[0]) {
                        setAttachedFileName(e.target.files[0].name);
                      }
                    }}
                  />
                </label>
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-2.5 pt-3">
                <button
                  type="button"
                  onClick={handleCloseLeaveModal}
                  className="px-5 h-11 rounded-xl bg-[#f0f3ff] text-[#444651] font-bold hover:bg-[#e2e8f8]"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 h-11 rounded-xl bg-[#fea619] text-[#684000] font-bold hover:brightness-105 transition-all flex items-center gap-1.5 shadow-xs"
                >
                  <FileCheck2 className="w-4 h-4" />
                  <span>تأكيد وتسجيل الإجازة</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Success Toast */}
      {toastMessage && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 px-6 py-3.5 rounded-2xl shadow-2xl bg-[#00311f] text-white animate-in slide-in-from-bottom-5">
          <Check className="w-5 h-5 text-[#27c38a]" />
          <span className="text-xs font-bold">{toastMessage}</span>
        </div>
      )}

      {/* Excel Export Toast */}
      {excelToast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 px-6 py-3.5 rounded-2xl shadow-2xl bg-white text-[#151c27] border border-[#e2e8f8] animate-in slide-in-from-bottom-5">
          <div className="w-8 h-8 rounded-xl bg-[#e6f8f0] text-[#059669] flex items-center justify-center">
            <Check className="w-5 h-5" />
          </div>
          <div className="flex flex-col text-xs">
            <span className="font-bold text-[#151c27]">بدء التصدير بنجاح</span>
            <span className="text-[#757682]">تم تجهيز وتنزيل ملف Excel لكشف الحضور الميداني</span>
          </div>
        </div>
      )}
    </div>
  );
};
