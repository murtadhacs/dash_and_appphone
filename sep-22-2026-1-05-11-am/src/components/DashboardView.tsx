import React, { useState } from 'react';
import { 
  Gauge, 
  Download, 
  UserPlus, 
  Users, 
  UserCheck, 
  UserX, 
  Clock, 
  Fingerprint, 
  ArrowLeft, 
  CheckCircle2, 
  RefreshCw, 
  Zap, 
  Send, 
  Printer,
  Sparkles,
  School
} from 'lucide-react';
import { LIVE_ATTENDANCE_STREAM } from '../data/mockData';
import { NavigationTab } from '../types';

interface DashboardViewProps {
  onNavigate: (tab: NavigationTab) => void;
  onOpenQuickLeave: () => void;
  onOpenAddStudent: () => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({
  onNavigate,
  onOpenQuickLeave,
  onOpenAddStudent,
}) => {
  const [feedRecords, setFeedRecords] = useState(LIVE_ATTENDANCE_STREAM);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [broadcastSent, setBroadcastSent] = useState(false);

  const handleRefreshFeed = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      // Simulate an incoming biometric scan
      const now = new Date();
      const timeStr = now.toLocaleTimeString('ar-SA', { hour12: true });
      const newEntry = {
        id: `ATT-${Date.now()}`,
        studentId: 'STD-1099881',
        studentName: 'فيصل نايف المطيري',
        grade: 'الصف الثالث الابتدائي (أ)',
        section: 'أ',
        time: timeStr,
        date: '2026-09-21',
        status: 'present' as const,
        notes: 'بصمة حية من البوابة 1',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKfC8mSlJH2J5-k7aFBhJemdYGlAfXgGc55eQd9koQ2SkWpprsMPABFJ4P-iDzoV8bU-hrwKgMW8ZP_A0b2DStDCqih3TxODsQ6gWfWgr9zetI3WsEyiO2YAP8Wm25RdAxs4X31L3cq_eZDeKIWK4_mkntGxZMHyHKzE_1RxlNflbFlT11QJ-K-ZaBRHRoW7EaS1rKaskR4jbQB0s_dZN4cQQWkiCY3y5lKb-oDW84_trKvoXAzV_GeA',
        method: 'fingerprint' as const,
      };

      setFeedRecords(prev => [newEntry, ...prev.slice(0, 4)]);
      setIsRefreshing(false);
    }, 600);
  };

  const handleBroadcast = () => {
    setBroadcastSent(true);
    setTimeout(() => setBroadcastSent(false), 3000);
  };

  return (
    <div className="flex flex-col w-full gap-5">
      {/* Top Banner: Master Operational Dashboard */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 bg-white p-5 rounded-2xl shadow-xs border border-[#e2e8f8]">
        <div className="flex items-center gap-4 min-w-0">
          <div className="w-12 h-12 rounded-xl bg-[#1e3a8a] text-white flex items-center justify-center shadow-md shrink-0">
            <Gauge className="w-7 h-7 text-white" />
          </div>
          <div className="flex flex-col truncate">
            <div className="flex items-center gap-2.5">
              <h1 className="text-xl font-bold text-[#00236f]">
                لوحة القيادة الميدانية العامة
              </h1>
              <span className="bg-[#e6f8f0] text-[#004a31] text-xs px-2.5 py-0.5 rounded-full flex items-center gap-1.5 font-bold border border-[#bbf7d0]">
                <span className="w-2 h-2 rounded-full bg-[#10b981] animate-pulse"></span>
                بيانات فورية
              </span>
            </div>
            <p className="text-xs text-[#444651] mt-0.5">
              متابعة نبض الحضور المدرسي وحركات الدخول لبوابة أطفال المستقبل لليوم الدراسي الحالي
            </p>
          </div>
        </div>

        {/* Top Action Buttons */}
        <div className="flex items-center gap-2.5 shrink-0">
          <button 
            id="export-daily-report-btn"
            onClick={() => {
              window.print();
            }}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#f0f3ff] text-[#151c27] hover:bg-[#e2e8f8] transition-colors border border-[#e2e8f8] text-xs font-bold"
          >
            <Download className="w-4 h-4 text-[#757682]" />
            <span>تصدير التقرير اليومي</span>
          </button>
          <button 
            id="quick-leave-btn"
            onClick={onOpenQuickLeave}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#1e3a8a] text-white hover:bg-[#00236f] transition-all shadow-sm text-xs font-bold active:scale-95"
          >
            <UserPlus className="w-4 h-4" />
            <span>تسجيل استئذان فوري</span>
          </button>
        </div>
      </div>

      {/* 5 KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-3.5">
        {/* Card 1: Registered Students */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col justify-between hover:shadow-md transition-all group">
          <div className="flex items-start justify-between">
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">إجمالي الطلاب المسجلين</span>
              <div className="flex items-baseline gap-1 mt-1.5">
                <span className="text-2xl font-bold text-[#151c27]">842</span>
                <span className="text-xs text-[#757682]">طالب</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-[#e7eefe] text-[#1e3a8a] flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 pt-2 border-t border-[#f0f3ff] flex items-center justify-between text-xs text-[#444651]">
            <span className="flex items-center gap-1 text-[#1e3a8a] font-semibold">
              <School className="w-3.5 h-3.5" />
              12 مرحلة وفصل
            </span>
            <span className="text-[#757682]">مُحدّث</span>
          </div>
        </div>

        {/* Card 2: Parents */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col justify-between hover:shadow-md transition-all group">
          <div className="flex items-start justify-between">
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">إجمالي أولياء الأمور</span>
              <div className="flex items-baseline gap-1 mt-1.5">
                <span className="text-2xl font-bold text-[#151c27]">615</span>
                <span className="text-xs text-[#757682]">ولي أمر</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-[#e7eefe] text-[#00236f] flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 pt-2 border-t border-[#f0f3ff] flex items-center justify-between text-xs text-[#444651]">
            <span className="text-[#757682]">تطبيق ولي الأمر</span>
            <span className="text-[#10b981] font-semibold">نشط</span>
          </div>
        </div>

        {/* Card 3: Present Students */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col justify-between hover:shadow-md transition-all group">
          <div className="flex items-start justify-between">
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">الحاضرون اليوم</span>
              <div className="flex items-baseline gap-1 mt-1.5">
                <span className="text-2xl font-bold text-[#10b981]">789</span>
                <span className="text-xs text-[#757682]">طالب</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-[#ecfdf5] text-[#059669] flex items-center justify-center shrink-0">
              <UserCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 pt-2 border-t border-[#f0f3ff] flex items-center justify-between text-xs">
            <span className="text-[#059669] font-bold">93.7% من الإجمالي</span>
            <span className="text-[#757682]">نسبة قياسية</span>
          </div>
        </div>

        {/* Card 4: Absent Students */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col justify-between hover:shadow-md transition-all group">
          <div className="flex items-start justify-between">
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">الغائبون اليوم</span>
              <div className="flex items-baseline gap-1 mt-1.5">
                <span className="text-2xl font-bold text-[#ef4444]">32</span>
                <span className="text-xs text-[#757682]">طالب</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-[#fee2e2] text-[#dc2626] flex items-center justify-center shrink-0">
              <UserX className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 pt-2 border-t border-[#f0f3ff] flex items-center justify-between text-xs text-[#444651]">
            <span className="text-[#dc2626] font-semibold">18 غير مبرر</span>
            <span className="text-[#757682]">14 بإشعار</span>
          </div>
        </div>

        {/* Card 5: Excused Leaves */}
        <div className="bg-white rounded-2xl p-4 shadow-xs border border-[#e2e8f8] flex flex-col justify-between hover:shadow-md transition-all group">
          <div className="flex items-start justify-between">
            <div className="flex flex-col">
              <span className="text-xs font-medium text-[#444651]">المجازون</span>
              <div className="flex items-baseline gap-1 mt-1.5">
                <span className="text-2xl font-bold text-[#d97706]">21</span>
                <span className="text-xs text-[#757682]">طالب</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-xl bg-[#fef3c7] text-[#b45309] flex items-center justify-center shrink-0">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 pt-2 border-t border-[#f0f3ff] flex items-center justify-between text-xs text-[#444651]">
            <span className="text-[#757682]">عبر البوابة الرقمية</span>
            <span className="text-[#d97706] font-semibold">معتمد رسمياً</span>
          </div>
        </div>
      </div>

      {/* Middle Row: Donut Chart Analysis & Real-time Biometric Stream */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-5">
        {/* Left column in RTL: Donut Chart Analysis (5 cols) */}
        <div className="xl:col-span-5 bg-white rounded-2xl p-5 shadow-xs border border-[#e2e8f8] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                <Sparkles className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-sm font-bold text-[#151c27]">تحليل الحضور اللحظي</h2>
                <p className="text-[11px] text-[#757682]">توزيع الطلاب المسجلين لليوم الدراسي الحالي</p>
              </div>
            </div>
            <span className="text-[#757682] text-xs bg-[#f0f3ff] px-2.5 py-1 rounded-full font-semibold">
              إجمالي: 842 طالب
            </span>
          </div>

          {/* Donut SVG visualization */}
          <div className="relative flex flex-col items-center justify-center my-6">
            <div className="w-56 h-56 relative flex items-center justify-center">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 240 240">
                <defs>
                  <filter id="emerald-subtle-glow" x="-10%" y="-10%" width="120%" height="120%">
                    <feDropShadow dx="0" dy="2" stdDeviation="3" floodColor="#10b981" floodOpacity="0.25" />
                  </filter>
                </defs>
                {/* Background track */}
                <circle cx="120" cy="120" r="92" fill="none" stroke="#f0f3ff" strokeWidth="18" />
                {/* Green Present segment (93.7%) */}
                <circle 
                  cx="120" 
                  cy="120" 
                  r="92" 
                  fill="none" 
                  stroke="#10b981" 
                  strokeWidth="18" 
                  strokeDasharray="541.6 36.4" 
                  strokeDashoffset="0" 
                  filter="url(#emerald-subtle-glow)"
                  className="transition-all duration-1000 ease-out" 
                />
                {/* Red Absent segment (3.8%) */}
                <circle 
                  cx="120" 
                  cy="120" 
                  r="92" 
                  fill="none" 
                  stroke="#ef4444" 
                  strokeWidth="18" 
                  strokeDasharray="21.9 556.1" 
                  strokeDashoffset="-541.6" 
                  className="transition-all duration-1000 ease-out" 
                />
                {/* Amber Excused segment (2.5%) */}
                <circle 
                  cx="120" 
                  cy="120" 
                  r="92" 
                  fill="none" 
                  stroke="#f59e0b" 
                  strokeWidth="18" 
                  strokeDasharray="14.4 563.6" 
                  strokeDashoffset="-563.5" 
                  className="transition-all duration-1000 ease-out" 
                />
              </svg>

              {/* Center text badge */}
              <div className="absolute flex flex-col items-center justify-center text-center px-4">
                <span className="text-3xl font-bold text-[#111827] leading-none tracking-tight">
                  93.7%
                </span>
                <span className="text-xs font-semibold text-[#444651] mt-2 mb-1.5">
                  نسبة الالتزام الإجمالية
                </span>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#ecfdf5] text-[#059669] border border-[#bbf7d0]">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#10b981] animate-pulse"></span>
                  ممتاز (فوق الهدف)
                </span>
              </div>
            </div>
          </div>

          {/* Breakdown summary */}
          <div className="flex flex-col gap-2.5 bg-[#f0f3ff]/70 p-3.5 rounded-xl border border-[#e2e8f8]">
            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#10b981]"></span>
                <span className="text-[#151c27] font-semibold">حاضرون في المدرسة</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#151c27]">789 طالب</span>
                <span className="text-[#757682] w-12 text-left font-mono">(93.7%)</span>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#ef4444]"></span>
                <span className="text-[#151c27] font-semibold">غياب غير مسوّغ</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#ef4444]">32 طالب</span>
                <span className="text-[#757682] w-12 text-left font-mono">(3.8%)</span>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#f59e0b]"></span>
                <span className="text-[#151c27] font-semibold">مستأذنون ومجازون رسمياً</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#b45309]">21 طالب</span>
                <span className="text-[#757682] w-12 text-left font-mono">(2.5%)</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right column in RTL: Live Biometric Stream (7 cols) */}
        <div className="xl:col-span-7 bg-white rounded-2xl p-5 shadow-xs border border-[#e2e8f8] flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                  <Fingerprint className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-sm font-bold text-[#151c27]">بث البصمات المباشر (الحركات اللحظية)</h2>
                  <p className="text-[11px] text-[#757682]">تسجيل الدخول الحي عبر بوابات القياس الذكية</p>
                </div>
              </div>
              <button 
                onClick={() => onNavigate('attendance')}
                className="text-xs text-[#00236f] hover:text-[#1e3a8a] font-bold flex items-center gap-1 transition-colors"
              >
                <span>سجل الحركات الكامل</span>
                <ArrowLeft className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Live Feed Table */}
            <div className="overflow-x-auto">
              <table className="w-full text-right border-collapse text-xs">
                <thead>
                  <tr className="bg-[#f0f3ff] text-[#444651] font-bold">
                    <th className="py-2.5 px-3 rounded-r-lg">الطالب</th>
                    <th className="py-2.5 px-3">المرحلة والفصل</th>
                    <th className="py-2.5 px-3">وقت البصمة</th>
                    <th className="py-2.5 px-3 rounded-l-lg text-center">حالة الدخول</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#f0f3ff]">
                  {feedRecords.map((item) => (
                    <tr key={item.id} className="hover:bg-[#f0f3ff]/60 transition-colors">
                      <td className="py-2.5 px-3">
                        <div className="flex items-center gap-2.5">
                          <img 
                            src={item.avatarUrl} 
                            alt={item.studentName} 
                            className="w-8 h-8 rounded-full object-cover shadow-xs shrink-0 ring-1 ring-[#e2e8f8]"
                          />
                          <div className="flex flex-col">
                            <span className="font-bold text-[#151c27]">{item.studentName}</span>
                            <span className="text-[10px] text-[#757682]">رقم الهوية: {item.studentId.replace('STD-', '')}</span>
                          </div>
                        </div>
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-[#151c27]">{item.grade}</td>
                      <td className="py-2.5 px-3 text-[#444651] font-mono text-[11px]">{item.time}</td>
                      <td className="py-2.5 px-3 text-center">
                        <span className="bg-[#ecfdf5] text-[#059669] text-[11px] px-2.5 py-0.5 rounded-full inline-flex items-center gap-1 font-bold border border-[#bbf7d0]">
                          <CheckCircle2 className="w-3.5 h-3.5 text-[#10b981]" />
                          مؤكد
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Sync Ticker & Manual Trigger */}
          <div className="flex items-center justify-between pt-3 mt-3 bg-[#f0f3ff] p-3 rounded-xl border border-[#e2e8f8]">
            <div className="flex items-center gap-2.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#10b981] animate-ping"></span>
              <span className="text-xs text-[#444651] font-medium">
                مزامنة أجهزة البصمة سارية - زمن الاستجابة 18ms
              </span>
            </div>
            <button 
              id="refresh-feed-btn"
              onClick={handleRefreshFeed}
              disabled={isRefreshing}
              className="p-1.5 rounded-lg text-[#757682] hover:text-[#00236f] hover:bg-[#e2e8f8] transition-all"
              title="تحديث البث الآن"
            >
              <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin text-[#00236f]' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Row: Quick Actions for Principal / Admin */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 bg-white rounded-2xl p-5 shadow-xs border border-[#e2e8f8] flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2.5 mb-4">
              <div className="w-8 h-8 rounded-xl bg-[#e7eefe] flex items-center justify-center text-[#1e3a8a]">
                <Zap className="w-4 h-4" />
              </div>
              <h3 className="text-sm font-bold text-[#151c27]">إجراءات سريعة لمدير النظام</h3>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Action 1: Add Student */}
              <button 
                id="quick-add-student-btn"
                onClick={onOpenAddStudent}
                className="flex flex-col items-center justify-center p-4 rounded-xl bg-[#f0f3ff] hover:bg-[#e2e8f8] transition-all group text-center border border-[#e2e8f8]"
              >
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-[#1e3a8a] shadow-xs mb-2 group-hover:scale-105 transition-transform">
                  <UserPlus className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-[#151c27]">تسجيل طالب</span>
                <span className="text-[11px] text-[#757682] mt-0.5">إضافة ملف أكاديمي</span>
              </button>

              {/* Action 2: Urgent Notice */}
              <button 
                id="quick-broadcast-btn"
                onClick={handleBroadcast}
                className="flex flex-col items-center justify-center p-4 rounded-xl bg-[#f0f3ff] hover:bg-[#e2e8f8] transition-all group text-center border border-[#e2e8f8]"
              >
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-[#d97706] shadow-xs mb-2 group-hover:scale-105 transition-transform">
                  <Send className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-[#151c27]">تعميم عاجل</span>
                <span className="text-[11px] text-[#757682] mt-0.5">إرسال لأولياء الأمور</span>
              </button>

              {/* Action 3: Print Rosters */}
              <button 
                id="quick-print-btn"
                onClick={() => window.print()}
                className="flex flex-col items-center justify-center p-4 rounded-xl bg-[#f0f3ff] hover:bg-[#e2e8f8] transition-all group text-center border border-[#e2e8f8]"
              >
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-[#059669] shadow-xs mb-2 group-hover:scale-105 transition-transform">
                  <Printer className="w-5 h-5" />
                </div>
                <span className="text-xs font-bold text-[#151c27]">طباعة الكشوف</span>
                <span className="text-[11px] text-[#757682] mt-0.5">تقرير الصباح اليومي</span>
              </button>
            </div>

            {broadcastSent && (
              <div className="mt-3 p-2 bg-[#ecfdf5] border border-[#bbf7d0] text-[#059669] text-xs rounded-xl text-center font-bold animate-in fade-in">
                ✓ تم إرسال التعميم الفوري عبر WhatsApp وSMS لجميع أولياء الأمور (615 مستلم)
              </div>
            )}
          </div>

          <div className="mt-4 pt-3 border-t border-[#f0f3ff] flex items-center justify-between text-[#444651] text-xs">
            <span>آخر إقفال دفتري: أمس 02:15 م</span>
            <span className="text-[#10b981] font-bold">سليم 100%</span>
          </div>
        </div>

        {/* System Health Card */}
        <div className="bg-white rounded-2xl p-5 shadow-xs border border-[#e2e8f8] flex flex-col justify-between">
          <div>
            <span className="text-xs font-bold text-[#151c27] block mb-2">حالة البنية التحتية</span>
            <div className="space-y-2.5">
              <div className="flex items-center justify-between text-xs">
                <span className="text-[#444651]">قارئ البوابة الرئيسية (RFID)</span>
                <span className="text-[#10b981] font-bold">متصل</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-[#444651]">ماسح الروضة (Biometric)</span>
                <span className="text-[#10b981] font-bold">متصل</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-[#444651]">بوابة الحافلات الذكية</span>
                <span className="text-[#10b981] font-bold">متصل</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-[#444651]">خادم المزامنة المحلي</span>
                <span className="text-[#10b981] font-bold">متزامن 100%</span>
              </div>
            </div>
          </div>
          <button 
            onClick={() => onNavigate('devices')}
            className="w-full mt-4 py-2 bg-[#f0f3ff] hover:bg-[#e2e8f8] text-[#00236f] text-xs font-bold rounded-xl transition-colors text-center"
          >
            إدارة البوابات والأجهزة
          </button>
        </div>
      </div>
    </div>
  );
};
