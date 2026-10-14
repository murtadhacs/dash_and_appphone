import React, { useState } from 'react';
import { 
  Building2, 
  School, 
  MessageSquare, 
  Mail, 
  CheckCircle2, 
  Clock, 
  Send, 
  Save, 
  RotateCcw, 
  Sliders, 
  ShieldCheck,
  BellRing
} from 'lucide-react';
import { SchoolSettings } from '../types';
import { INITIAL_SETTINGS } from '../data/mockData';

export const SettingsView: React.FC = () => {
  const [settings, setSettings] = useState<SchoolSettings>(INITIAL_SETTINGS);
  const [initialSettings] = useState<SchoolSettings>(INITIAL_SETTINGS);

  // Form State
  const [schoolName, setSchoolName] = useState(settings.schoolName);
  const [whatsappNumber, setWhatsappNumber] = useState(settings.whatsappNumber);
  const [supportEmail, setSupportEmail] = useState(settings.supportEmail);
  const [openGateTime, setOpenGateTime] = useState(settings.openGateTime);
  const [lateTimeThreshold, setLateTimeThreshold] = useState(settings.lateTimeThreshold);
  const [notifyParentSwitch, setNotifyParentSwitch] = useState(settings.notifyParentSwitch);

  // UI status
  const [isSaving, setIsSaving] = useState(false);
  const [saveProgress, setSaveProgress] = useState(0);
  const [showToast, setShowToast] = useState(false);

  const isDirty =
    schoolName !== initialSettings.schoolName ||
    whatsappNumber !== initialSettings.whatsappNumber ||
    supportEmail !== initialSettings.supportEmail ||
    openGateTime !== initialSettings.openGateTime ||
    lateTimeThreshold !== initialSettings.lateTimeThreshold ||
    notifyParentSwitch !== initialSettings.notifyParentSwitch;

  const handleReset = () => {
    setSchoolName(initialSettings.schoolName);
    setWhatsappNumber(initialSettings.whatsappNumber);
    setSupportEmail(initialSettings.supportEmail);
    setOpenGateTime(initialSettings.openGateTime);
    setLateTimeThreshold(initialSettings.lateTimeThreshold);
    setNotifyParentSwitch(initialSettings.notifyParentSwitch);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isDirty || isSaving) return;

    setIsSaving(true);
    setSaveProgress(30);

    setTimeout(() => {
      setSaveProgress(75);
    }, 300);

    setTimeout(() => {
      setSaveProgress(100);
      setTimeout(() => {
        setSettings({
          schoolName,
          whatsappNumber,
          supportEmail,
          openGateTime,
          lateTimeThreshold,
          notifyParentSwitch,
        });
        setIsSaving(false);
        setSaveProgress(0);
        setShowToast(true);
        setTimeout(() => setShowToast(false), 3500);
      }, 400);
    }, 700);
  };

  return (
    <div className="flex flex-col w-full max-w-2xl mx-auto select-none pb-12">
      {/* Header Section */}
      <div className="mb-6 flex flex-col gap-1">
        <div className="flex items-center gap-2 text-xs text-[#444651]">
          <Sliders className="w-3.5 h-3.5 text-[#757682]" />
          <span>النظام الأكاديمي الإداري</span>
          <span className="text-[#c5c5d3]">/</span>
          <span className="text-[#00236f] font-bold">تفضيلات المنظومة</span>
        </div>
        <h1 className="text-xl font-bold text-[#00236f] tracking-tight">
          إعدادات منصة المدرسة
        </h1>
        <p className="text-xs text-[#444651] leading-relaxed">
          تخصيص المعايير التشغيلية الميدانية، قنوات التواصل المعتمدة لأولياء الأمور، ومحددات ضبط الحضور التلقائي للبوابات الذكية.
        </p>
      </div>

      {/* Main Settings Form Card */}
      <form
        onSubmit={handleSave}
        className="bg-white rounded-2xl shadow-xs border border-[#e2e8f8] overflow-hidden flex flex-col"
      >
        {/* Animated Progress Bar */}
        {isSaving && (
          <div className="w-full h-1.5 bg-[#e2e8f8] overflow-hidden">
            <div
              className="h-full bg-[#fea619] transition-all duration-300 ease-out"
              style={{ width: `${saveProgress}%` }}
            />
          </div>
        )}

        <div className="p-6 flex flex-col gap-6 text-xs">
          {/* Group 1: General Info */}
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-2.5 pb-2 border-b border-[#f0f3ff]">
              <span className="w-8 h-8 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                <Building2 className="w-4 h-4" />
              </span>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-[#151c27]">
                  الهوية الأكاديمية والاتصال
                </span>
                <span className="text-[11px] text-[#757682]">
                  البيانات الظاهرة في تقارير ورسائل الإشعارات
                </span>
              </div>
            </div>

            {/* School Name Field */}
            <div className="flex flex-col gap-1.5">
              <label className="font-bold text-[#151c27] flex items-center justify-between">
                <span>اسم المدرسة</span>
                <span className="text-[11px] text-[#757682]">مطلوب</span>
              </label>
              <div className="relative flex items-center">
                <School className="w-4 h-4 absolute right-3.5 text-[#757682] pointer-events-none" />
                <input
                  type="text"
                  required
                  value={schoolName}
                  onChange={(e) => setSchoolName(e.target.value)}
                  className="w-full h-11 pr-10 pl-4 bg-[#f0f3ff] rounded-xl text-xs text-[#151c27] font-semibold border border-[#e2e8f8] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
                />
              </div>
            </div>

            {/* WhatsApp Field */}
            <div className="flex flex-col gap-1.5">
              <label className="font-bold text-[#151c27] flex items-center justify-between">
                <span>رقم واتساب الإشعارات الرسمية</span>
                <span className="text-[11px] text-[#059669] font-bold flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" /> موثق ومعتمد
                </span>
              </label>
              <div className="relative flex items-center">
                <MessageSquare className="w-4 h-4 absolute right-3.5 text-[#757682] pointer-events-none" />
                <input
                  type="text"
                  dir="ltr"
                  required
                  value={whatsappNumber}
                  onChange={(e) => setWhatsappNumber(e.target.value)}
                  className="w-full h-11 pr-10 pl-4 bg-[#f0f3ff] rounded-xl text-xs font-mono text-left text-[#151c27] border border-[#e2e8f8] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
                />
              </div>
            </div>

            {/* Support Email */}
            <div className="flex flex-col gap-1.5">
              <label className="font-bold text-[#151c27]">
                البريد الإلكتروني للدعم الفني
              </label>
              <div className="relative flex items-center">
                <Mail className="w-4 h-4 absolute right-3.5 text-[#757682] pointer-events-none" />
                <input
                  type="email"
                  dir="ltr"
                  required
                  value={supportEmail}
                  onChange={(e) => setSupportEmail(e.target.value)}
                  className="w-full h-11 pr-10 pl-4 bg-[#f0f3ff] rounded-xl text-xs font-mono text-left text-[#151c27] border border-[#e2e8f8] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
                />
              </div>
            </div>
          </div>

          <div className="w-full h-px bg-[#e2e8f8]"></div>

          {/* Group 2: Attendance Timing Policies */}
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-2.5 pb-2 border-b border-[#f0f3ff]">
              <span className="w-8 h-8 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                <Clock className="w-4 h-4" />
              </span>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-[#151c27]">
                  مواعيد وسياسات الحضور والانصراف
                </span>
                <span className="text-[11px] text-[#757682]">
                  توقيت فتح الأجهزة وبدء احتساب التأخير اليومي
                </span>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27]">وقت فتح البوابة الصباحية</label>
                <input
                  type="time"
                  value={openGateTime}
                  onChange={(e) => setOpenGateTime(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-xs font-mono font-bold text-[#151c27] focus:bg-white focus:outline-none"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27]">موعد احتساب التأخير</label>
                <input
                  type="time"
                  value={lateTimeThreshold}
                  onChange={(e) => setLateTimeThreshold(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-xs font-mono font-bold text-[#151c27] focus:bg-white focus:outline-none"
                />
              </div>
            </div>
          </div>

          <div className="w-full h-px bg-[#e2e8f8]"></div>

          {/* Group 3: Automation & Notification Rules */}
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-2.5 pb-2 border-b border-[#f0f3ff]">
              <span className="w-8 h-8 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                <BellRing className="w-4 h-4" />
              </span>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-[#151c27]">
                  الأتمتة والإشعار اللحظي
                </span>
                <span className="text-[11px] text-[#757682]">
                  بث حالات الدخول والخروج لأولياء الأمور فورياً
                </span>
              </div>
            </div>

            {/* Real-Time Switch Box */}
            <div 
              onClick={() => setNotifyParentSwitch(!notifyParentSwitch)}
              className="bg-[#f0f3ff] hover:bg-[#e2e8f8] p-4 rounded-xl transition-colors cursor-pointer border border-[#e2e8f8]"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex flex-col gap-1">
                  <span className="text-xs font-bold text-[#151c27]">
                    إرسال إشعار فوري لولي الأمر عبر SMS وتطبيق ولي الأمر
                  </span>
                  <p className="text-[11px] text-[#444651] leading-relaxed">
                    يتم إطلاق رسالة تنبيه وبث إشعار Push فور إتمام مسح بطاقة أو بصمة الطالب لدى جهاز البوابة الإلكترونية.
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer shrink-0 mt-0.5">
                  <input
                    type="checkbox"
                    checked={notifyParentSwitch}
                    onChange={(e) => setNotifyParentSwitch(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-[#c5c5d3] peer-focus:outline-none rounded-full peer peer-checked:after:-translate-x-full rtl:peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:right-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#1e3a8a]"></div>
                </label>
              </div>
            </div>
          </div>
        </div>

        {/* Action Panel / Dock */}
        <div className="px-6 py-4 bg-[#f0f3ff] border-t border-[#e2e8f8] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span
              className={`w-2.5 h-2.5 rounded-full ${
                isDirty ? 'bg-[#fea619]' : 'bg-[#10b981]'
              }`}
            />
            <span className="text-xs text-[#444651] font-semibold">
              {isDirty ? 'توجد تغييرات غير محفوظة' : 'جميع الإعدادات محدثة'}
            </span>
          </div>

          <div className="flex items-center gap-2">
            {isDirty && (
              <button
                type="button"
                onClick={handleReset}
                className="px-4 py-2 rounded-xl bg-white text-[#444651] border border-[#e2e8f8] hover:bg-gray-100 text-xs font-bold transition-colors"
              >
                تراجع
              </button>
            )}

            <button
              type="submit"
              disabled={!isDirty || isSaving}
              className={`px-6 py-2 rounded-xl bg-[#1e3a8a] text-white text-xs font-bold flex items-center gap-2 transition-all shadow-xs ${
                !isDirty || isSaving ? 'opacity-50 cursor-not-allowed' : 'hover:bg-[#00236f] active:scale-95'
              }`}
            >
              <Save className="w-4 h-4" />
              <span>{isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات'}</span>
            </button>
          </div>
        </div>
      </form>

      {/* Toast Alert */}
      {showToast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2.5 bg-[#004a31] text-white px-6 py-3 rounded-2xl shadow-2xl animate-in slide-in-from-bottom-5">
          <CheckCircle2 className="w-5 h-5 text-[#27c38a]" />
          <span className="text-xs font-bold">تم حفظ إعدادات المدرسة بنجاح</span>
        </div>
      )}
    </div>
  );
};
