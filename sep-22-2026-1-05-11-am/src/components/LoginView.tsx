import React, { useState } from 'react';
import { 
  Lock, 
  Mail, 
  Eye, 
  EyeOff, 
  LogIn, 
  School, 
  CheckCircle2, 
  TrendingUp, 
  ShieldCheck, 
  Building2, 
  Zap, 
  AlertCircle,
  X,
  Users
} from 'lucide-react';
import { APP_LOGO } from '../data/mockData';

interface LoginViewProps {
  onLoginSuccess: () => void;
}

export const LoginView: React.FC<LoginViewProps> = ({ onLoginSuccess }) => {
  const [identity, setIdentity] = useState('admin@futurekids.edu.sa');
  const [password, setPassword] = useState('demo1234');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setIsLoading(true);

    setTimeout(() => {
      setIsLoading(false);
      // Demo validation accepts admin, admin@futurekids.edu.sa, or any credentials
      if (identity && password) {
        onLoginSuccess();
      } else {
        setErrorMsg('البريد الأكاديمي أو كلمة المرور غير متطابقة مع سجلات إدارة المدرسة.');
      }
    }, 700);
  };

  const handleQuickDemoFill = () => {
    setIdentity('admin@futurekids.edu.sa');
    setPassword('demo1234');
    setErrorMsg(null);
  };

  return (
    <div className="min-h-screen w-full bg-[#f9f9ff] flex items-center justify-center p-4 lg:p-8 select-none">
      <div className="w-full max-w-5xl overflow-hidden rounded-2xl bg-white shadow-xl border border-[#e2e8f8] grid grid-cols-1 lg:grid-cols-12 min-h-[640px]">
        {/* Right Column: Login Form & Administrative Access (RTL Leading) */}
        <div className="lg:col-span-6 xl:col-span-5 p-6 md:p-10 flex flex-col justify-between bg-white">
          <div>
            {/* Brand Header */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-2.5">
                <img
                  src={APP_LOGO}
                  alt="شعار مدارس أطفال المستقبل"
                  className="h-10 w-auto object-contain"
                />
              </div>
              <button
                type="button"
                onClick={handleQuickDemoFill}
                className="text-[11px] font-bold text-[#00236f] bg-[#f0f3ff] hover:bg-[#e2e8f8] px-2.5 py-1 rounded-lg transition-colors border border-[#e2e8f8]"
              >
                تعبئة تجريبية
              </button>
            </div>

            {/* Greeting & Subheading */}
            <div className="mb-6">
              <div className="inline-block mb-1 text-[#00236f] text-xs font-bold">
                بوابة الإدارة المعتمدة
              </div>
              <h1 className="text-xl font-bold text-[#151c27] tracking-tight mb-2">
                مرحباً بك مجدداً في بوابة الإدارة
              </h1>
              <p className="text-xs text-[#444651]">
                يرجى إدخال بيانات الاعتماد الممنوحة للوصول السريع والآمن إلى لوحة التحكم المدرسية.
              </p>
            </div>

            {/* Error Banner */}
            {errorMsg && (
              <div className="mb-4 p-3 rounded-xl bg-[#fee2e2] text-[#dc2626] flex items-start gap-2.5 border border-[#fecaca] animate-in fade-in">
                <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                <div className="flex-1 text-xs">
                  <p className="font-bold">تعذر التحقق من بيانات الدخول</p>
                  <p className="text-[11px] text-[#dc2626] mt-0.5">{errorMsg}</p>
                </div>
                <button
                  type="button"
                  onClick={() => setErrorMsg(null)}
                  className="text-[#dc2626] hover:opacity-75"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Access Form */}
            <form onSubmit={handleSubmit} className="flex flex-col gap-4 text-xs">
              {/* Identity Input */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27] flex items-center justify-between">
                  <span>اسم المستخدم أو البريد الأكاديمي</span>
                  <span className="text-[#757682] text-[11px]">مُخصص للموظفين</span>
                </label>
                <div className="relative flex items-center">
                  <Mail className="w-4 h-4 absolute right-3.5 text-[#757682] pointer-events-none" />
                  <input
                    type="text"
                    required
                    value={identity}
                    onChange={(e) => setIdentity(e.target.value)}
                    placeholder="admin@futurekids.edu.sa"
                    className="w-full h-11 pr-10 pl-4 rounded-xl bg-[#f0f3ff] text-xs text-[#151c27] font-medium border border-[#e2e8f8] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
                  />
                </div>
              </div>

              {/* Password Field with Show/Hide Toggle */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27]">كلمة المرور</label>
                <div className="relative flex items-center">
                  <Lock className="w-4 h-4 absolute right-3.5 text-[#757682] pointer-events-none" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••••••"
                    className="w-full h-11 pr-10 pl-11 rounded-xl bg-[#f0f3ff] text-xs text-[#151c27] border border-[#e2e8f8] focus:bg-white focus:ring-2 focus:ring-[#1e3a8a] focus:outline-none transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute left-3 text-[#757682] hover:text-[#151c27] p-1"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Remember Me */}
              <div className="flex items-center justify-between pt-1">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="w-4 h-4 rounded accent-[#1e3a8a]"
                  />
                  <span className="text-xs text-[#444651]">تذكر هذا الجهاز لمدة 30 يوماً</span>
                </label>
              </div>

              {/* Primary Submit Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="mt-2 w-full h-11 rounded-xl bg-[#1e3a8a] hover:bg-[#00236f] text-white font-bold text-xs flex items-center justify-center gap-2 shadow-md transition-all active:scale-[0.99] disabled:opacity-75"
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                    <span>جارٍ التحقق...</span>
                  </span>
                ) : (
                  <span className="flex items-center gap-2">
                    <LogIn className="w-4 h-4" />
                    <span>تسجيل الدخول للنظام</span>
                  </span>
                )}
              </button>
            </form>
          </div>

          {/* Footer Policy Links */}
          <div className="pt-6 mt-6 border-t border-[#f0f3ff] flex flex-col sm:flex-row items-center justify-between gap-2 text-[#757682] text-[11px]">
            <span>© 2026 منصة مدارس أطفال المستقبل</span>
            <div className="flex items-center gap-3">
              <span className="hover:text-[#151c27] cursor-pointer">سياسة الخصوصية</span>
              <span>•</span>
              <span className="hover:text-[#151c27] cursor-pointer">الدعم الفني للإدارة</span>
            </div>
          </div>
        </div>

        {/* Left Column: Inspiring Administrative Cockpit Brand Space */}
        <div className="lg:col-span-6 xl:col-span-7 bg-[#00236f] text-white p-6 md:p-10 relative overflow-hidden flex flex-col justify-between">
          {/* Background Ambient Accents */}
          <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-[#1e3a8a]/40 blur-3xl pointer-events-none"></div>
          <div className="absolute -bottom-20 -right-20 w-80 h-80 rounded-full bg-[#fea619]/20 blur-3xl pointer-events-none"></div>

          {/* Top Section */}
          <div className="relative z-10 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-white/10 backdrop-blur flex items-center justify-center">
                <School className="w-5 h-5 text-[#fea619]" />
              </div>
              <div>
                <div className="text-sm font-bold text-white">مدارس أطفال المستقبل</div>
                <div className="text-[11px] text-white/70">نظام الإدارة المدرسية الموحد</div>
              </div>
            </div>

            <div className="hidden sm:flex items-center gap-2 bg-white/10 backdrop-blur px-3 py-1.5 rounded-full text-xs font-semibold">
              <span className="w-2 h-2 rounded-full bg-[#4edea3] animate-pulse"></span>
              <span>الأنظمة متصلة بنسبة 99.8%</span>
            </div>
          </div>

          {/* Middle Section: Visual Narrative */}
          <div className="relative z-10 my-8 flex flex-col gap-6">
            <div className="max-w-xl">
              <span className="inline-block px-3 py-1 rounded-full bg-[#fea619] text-[#684000] text-xs font-bold mb-3">
                منظومة القيادة المدرسية الذكية
              </span>
              <h2 className="text-2xl font-bold text-white mb-3 leading-snug">
                نصنع بيئة تعليمية آمنة ترعى إبداع وقيم قادة الغد
              </h2>
              <p className="text-xs text-white/80 leading-relaxed">
                تم تصميم لوحة التحكم الموحدة لتمكين المشرفين والمربين من تتبع الحضور، السجلات المهارية، والتقدم الأكاديمي بمرونة وسلاسة فائقة.
              </p>
            </div>

            {/* Bento Grid Metrics */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-3.5 rounded-xl bg-white/10 backdrop-blur flex flex-col justify-between border border-white/10">
                <div className="flex items-center justify-between text-[#ffddb8] mb-1.5 text-xs font-bold">
                  <span>الطلاب المسجلين</span>
                  <Users className="w-4 h-4" />
                </div>
                <div className="text-xl font-bold text-white">+2,480</div>
                <div className="text-[10px] text-white/70 mt-1 flex items-center gap-1">
                  <TrendingUp className="w-3 h-3 text-[#4edea3]" />
                  <span>معدل انتظام 98.4%</span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-white/10 backdrop-blur flex flex-col justify-between border border-white/10">
                <div className="flex items-center justify-between text-[#ffddb8] mb-1.5 text-xs font-bold">
                  <span>الشعب والفصول</span>
                  <Building2 className="w-4 h-4" />
                </div>
                <div className="text-xl font-bold text-white">78</div>
                <div className="text-[10px] text-white/70 mt-1 flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3 text-[#4edea3]" />
                  <span>100% كادر مكتمل</span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-white/10 backdrop-blur flex flex-col justify-between border border-white/10">
                <div className="flex items-center justify-between text-[#ffddb8] mb-1.5 text-xs font-bold">
                  <span>الحضور اليومي</span>
                  <Zap className="w-4 h-4" />
                </div>
                <div className="text-xl font-bold text-white">14,200</div>
                <div className="text-[10px] text-white/70 mt-1 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#4edea3]"></span>
                  <span>استجابة فورية 0.12s</span>
                </div>
              </div>
            </div>
          </div>

          {/* Bottom Compliance Badges */}
          <div className="relative z-10 pt-4 flex flex-wrap items-center justify-between gap-3 bg-white/5 backdrop-blur p-3 rounded-xl border border-white/10 text-xs">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-[#4edea3]" />
              <span className="font-semibold text-white">معايير حماية الخصوصية</span>
            </div>
            <div className="flex items-center gap-2 text-white/80 text-[11px]">
              <span className="w-2 h-2 rounded-full bg-[#4edea3]"></span>
              <span>بيئة سحابية معتمدة ISO 27001</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
