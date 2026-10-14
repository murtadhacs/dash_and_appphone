import React from 'react';
import { 
  LayoutDashboard, 
  GraduationCap, 
  CalendarCheck, 
  Fingerprint, 
  Settings,
  Menu,
  X
} from 'lucide-react';
import { NavigationTab } from '../types';
import { APP_LOGO } from '../data/mockData';

interface SidebarProps {
  currentTab: NavigationTab;
  onSelectTab: (tab: NavigationTab) => void;
  mobileOpen: boolean;
  onCloseMobile: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  mobileOpen,
  onCloseMobile,
}) => {
  const navItems = [
    { id: 'dashboard' as NavigationTab, label: 'لوحة التحكم', icon: LayoutDashboard },
    { id: 'students' as NavigationTab, label: 'الطلاب وأولياء الأمور', icon: GraduationCap },
    { id: 'attendance' as NavigationTab, label: 'الحضور والاجازات', icon: CalendarCheck },
    { id: 'devices' as NavigationTab, label: 'الأجهزة وبوابات الحضور', icon: Fingerprint },
    { id: 'settings' as NavigationTab, label: 'الإعدادات العامة', icon: Settings },
  ];

  return (
    <>
      {/* Backdrop for mobile */}
      {mobileOpen && (
        <div 
          className="fixed inset-0 bg-black/40 z-40 lg:hidden backdrop-blur-xs transition-opacity"
          onClick={onCloseMobile}
        />
      )}

      <aside 
        id="app-sidebar"
        className={`fixed right-0 top-0 h-full w-64 bg-white shadow-[0_1px_8px_rgba(0,0,0,0.04)] z-50 flex flex-col justify-between select-none border-l border-[#e2e8f8] transition-transform duration-300 ${
          mobileOpen ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="flex flex-col">
          {/* Logo & Brand Header */}
          <div className="h-16 px-4 flex items-center justify-between bg-[#f0f3ff] border-b border-[#e2e8f8]">
            <div className="flex items-center gap-2.5">
              <img 
                src={APP_LOGO} 
                alt="شعار نظام أطفال المستقبل" 
                className="h-9 w-auto object-contain shrink-0"
              />
              <div className="flex flex-col text-right">
                <span className="text-sm font-bold text-[#00236f] leading-tight">
                  أطفال المستقبل
                </span>
                <span className="text-[11px] text-[#444651] font-medium leading-none mt-0.5">
                  نظام الإدارة المدرسية
                </span>
              </div>
            </div>
            {/* Close button on mobile */}
            <button 
              onClick={onCloseMobile}
              className="lg:hidden p-1 rounded-lg text-gray-500 hover:bg-gray-200"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Section Header */}
          <div className="px-4 py-2.5">
            <span className="text-[11px] uppercase tracking-wider font-bold text-[#757682] px-2">
              القائمة الرئيسية
            </span>
          </div>

          {/* Nav Items */}
          <nav className="flex flex-col gap-1 px-2.5">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  id={`nav-item-${item.id}`}
                  onClick={() => {
                    onSelectTab(item.id);
                    onCloseMobile();
                  }}
                  className={`flex items-center gap-3 px-4 py-2.5 rounded-lg transition-all text-right w-full text-sm ${
                    isActive
                      ? 'bg-[#e7eefe] text-[#00236f] font-bold shadow-[inset_4px_0_0_0_#fea619]'
                      : 'text-[#444651] font-medium hover:bg-[#e2e8f8] hover:text-[#151c27]'
                  }`}
                >
                  <Icon className={`w-5 h-5 shrink-0 ${isActive ? 'text-[#00236f]' : 'text-[#757682]'}`} />
                  <span className="truncate">{item.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        {/* Server & System Status Footer */}
        <div className="p-3.5 bg-[#f0f3ff] border-t border-[#e2e8f8]">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[#004a31] relative flex">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#27c38a] opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#27c38a]"></span>
              </span>
              <span className="text-xs font-semibold text-[#444651]">خوادم النظام متصلة</span>
            </div>
            <span className="text-[11px] text-[#757682] font-mono font-semibold">v2.4</span>
          </div>
        </div>
      </aside>
    </>
  );
};
