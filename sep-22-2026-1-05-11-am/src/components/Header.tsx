import React, { useState } from 'react';
import { 
  Calendar, 
  CheckCircle2, 
  Bell, 
  HelpCircle, 
  LogOut, 
  Menu 
} from 'lucide-react';
import { ADMIN_AVATAR } from '../data/mockData';

interface HeaderProps {
  onToggleMobileSidebar: () => void;
  onLogout: () => void;
}

export const Header: React.FC<HeaderProps> = ({ 
  onToggleMobileSidebar, 
  onLogout 
}) => {
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [helpOpen, setHelpOpen] = useState(false);

  return (
    <header 
      id="app-header"
      className="fixed top-0 right-0 lg:right-64 left-0 h-16 bg-white/95 backdrop-blur-md shadow-[0_1px_8px_rgba(0,0,0,0.04)] z-40 flex items-center justify-between px-4 lg:px-6 border-b border-[#e2e8f8]"
    >
      {/* Right section in RTL (Leading) */}
      <div className="flex items-center gap-3">
        {/* Mobile Hamburger */}
        <button 
          id="mobile-menu-toggle"
          onClick={onToggleMobileSidebar}
          className="lg:hidden p-2 rounded-lg text-[#444651] hover:bg-[#e2e8f8] transition-colors"
          aria-label="القائمة"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Academic Semester Badge */}
        <div className="hidden sm:flex items-center gap-2 bg-[#f0f3ff] px-3.5 py-1.5 rounded-full border border-[#e2e8f8]">
          <Calendar className="w-4 h-4 text-[#757682]" />
          <span className="text-xs font-semibold text-[#444651]">
            الفصل الدراسي الثاني 1446هـ
          </span>
        </div>

        {/* Accredited Management Badge */}
        <div className="hidden md:flex items-center gap-1.5 text-[#444651] text-xs font-semibold">
          <CheckCircle2 className="w-4 h-4 text-[#004a31]" />
          <span>إدارة معتمدة</span>
        </div>
      </div>

      {/* Left section in RTL (Trailing) */}
      <div className="flex items-center gap-3 md:gap-5">
        {/* Notification & Help Icons */}
        <div className="flex items-center gap-1.5 relative">
          <button 
            id="notifications-btn"
            onClick={() => setNotificationsOpen(!notificationsOpen)}
            className="w-9 h-9 rounded-full flex items-center justify-center text-[#444651] hover:bg-[#e7eefe] hover:text-[#00236f] transition-colors relative"
            title="الإشعارات"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#fea619] ring-2 ring-white"></span>
          </button>

          {/* Quick Notification Dropdown */}
          {notificationsOpen && (
            <div className="absolute left-0 top-11 w-72 bg-white rounded-xl shadow-xl border border-[#e2e8f8] p-3 z-50 animate-in fade-in zoom-in-95">
              <div className="flex items-center justify-between pb-2 border-b border-[#e2e8f8] mb-2">
                <span className="text-xs font-bold text-[#00236f]">التنبيهات العاجلة</span>
                <span className="text-[10px] bg-[#f0f3ff] text-[#00236f] px-2 py-0.5 rounded-full font-bold">2 جديد</span>
              </div>
              <div className="flex flex-col gap-2 text-xs">
                <div className="p-2 rounded-lg bg-[#f0f3ff] text-[#151c27]">
                  <p className="font-semibold text-primary">اكتمال مزامنة البوابة الرئيسية</p>
                  <p className="text-[11px] text-[#757682] mt-0.5">تم تسجيل 789 بصمة حضور حتى 08:00 ص</p>
                </div>
                <div className="p-2 rounded-lg hover:bg-gray-50 text-[#151c27]">
                  <p className="font-semibold text-[#855300]">طلب إجازة معلق</p>
                  <p className="text-[11px] text-[#757682] mt-0.5">طلب عذر مرضي للطالب ريان الدوسري</p>
                </div>
              </div>
            </div>
          )}

          <button 
            id="help-btn"
            onClick={() => setHelpOpen(!helpOpen)}
            className="w-9 h-9 rounded-full flex items-center justify-center text-[#444651] hover:bg-[#e7eefe] hover:text-[#00236f] transition-colors"
            title="المساعدة والدعم"
          >
            <HelpCircle className="w-5 h-5" />
          </button>

          {helpOpen && (
            <div className="absolute left-0 top-11 w-64 bg-white rounded-xl shadow-xl border border-[#e2e8f8] p-3 z-50 text-xs">
              <p className="font-bold text-[#00236f] mb-1">دعم نظام أطفال المستقبل</p>
              <p className="text-[#444651] mb-2 text-[11px]">لأي استفسارات تقنية حول أجهزة البصمة وقارئ RFID اتصل على 920000000</p>
              <button 
                onClick={() => setHelpOpen(false)}
                className="w-full py-1 text-center bg-[#f0f3ff] text-[#00236f] font-bold rounded-lg"
              >
                إغلاق
              </button>
            </div>
          )}
        </div>

        {/* Separator */}
        <div className="w-px h-6 bg-[#e2e8f8]"></div>

        {/* Admin Profile */}
        <div className="flex items-center gap-2.5">
          <div className="hidden sm:flex flex-col text-left">
            <span className="text-xs font-bold text-[#151c27]">
              أ. عبد الرحمن السعيد
            </span>
            <span className="text-[11px] text-[#757682]">
              مدير النظام الأكاديمي
            </span>
          </div>
          <img 
            src={ADMIN_AVATAR} 
            alt="صورة مدير النظام" 
            className="w-9 h-9 rounded-full object-cover shadow-sm ring-2 ring-[#e2e8f8]"
          />
          <button 
            id="logout-btn"
            onClick={onLogout}
            className="flex items-center justify-center w-8 h-8 rounded-lg text-[#757682] hover:bg-[#ffdad6] hover:text-[#ba1a1a] transition-colors mr-1" 
            title="تسجيل الخروج"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
};
