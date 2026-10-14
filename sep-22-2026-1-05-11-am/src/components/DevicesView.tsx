import React, { useState } from 'react';
import { 
  Fingerprint, 
  SlidersHorizontal, 
  RefreshCw, 
  CheckCircle2, 
  MapPin, 
  Gauge, 
  Cpu, 
  Radio, 
  Wifi, 
  AlertCircle, 
  Check, 
  X, 
  Save, 
  Network, 
  Settings2, 
  RotateCw,
  Power
} from 'lucide-react';
import { DeviceInfo } from '../types';
import { INITIAL_DEVICES } from '../data/mockData';

export const DevicesView: React.FC = () => {
  const [devices, setDevices] = useState<DeviceInfo[]>(INITIAL_DEVICES);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingDevice, setEditingDevice] = useState<DeviceInfo>(INITIAL_DEVICES[0]);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form states
  const [serial, setSerial] = useState(INITIAL_DEVICES[0].serial);
  const [location, setLocation] = useState(INITIAL_DEVICES[0].location);
  const [protocol, setProtocol] = useState<'rfid' | 'biometric'>('rfid');
  const [isActive, setIsActive] = useState(true);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setIsRefreshing(false);
      showToast('تم تحديث حالة الاتصال بجميع البوابات (3/3 مستجيبة)');
    }, 800);
  };

  const openEditModal = (dev: DeviceInfo) => {
    setEditingDevice(dev);
    setSerial(dev.serial);
    setLocation(dev.location);
    setProtocol(dev.protocol);
    setIsActive(dev.isActive);
    setIsModalOpen(true);
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setDevices(prev =>
      prev.map(d => (d.id === editingDevice.id ? { ...d, serial, location, protocol, isActive } : d))
    );
    setIsModalOpen(false);
    showToast(`تم تحديث إعدادات الجهاز (${location}) بنجاح`);
  };

  const toggleDeviceActive = (id: string) => {
    setDevices(prev =>
      prev.map(d => {
        if (d.id === id) {
          const next = !d.isActive;
          showToast(`تم ${next ? 'تفعيل' : 'إيقاف مؤقت'} للوحدة ${d.serial}`);
          return { ...d, isActive: next, status: next ? 'online' : 'offline' };
        }
        return d;
      })
    );
  };

  const pingDevice = (d: DeviceInfo) => {
    showToast(`تم إرسال حزمة فحص للوحدة ${d.serial} - الاستجابة: ${d.latency}`);
  };

  return (
    <div className="flex flex-col w-full gap-5 select-none">
      {/* Top Section: Header, Metrics & Quick Actions */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex flex-col gap-1">
          <div className="flex items-center gap-2 text-[#444651] text-xs">
            <Fingerprint className="w-4 h-4 text-[#1e3a8a]" />
            <span>البنية التحتية وإنترنت الأشياء (IoT)</span>
            <span className="text-[#c5c5d3]">/</span>
            <span className="text-[#fea619] font-bold">جهاز الحضور الذكي</span>
          </div>
          <h1 className="text-xl font-bold text-[#00236f] tracking-tight">
            إدارة جهاز الحضور وقراءة البصمة الذكي
          </h1>
          <p className="text-xs text-[#444651] max-w-2xl">
            مراقبة حية لوحدة قراءة RFID والبصمة الموحدة، ومتابعة حالة الاتصال ومزامنة الحضور اللحظية.
          </p>
        </div>

        {/* Actions Bar */}
        <div className="flex items-center gap-2.5 self-start md:self-auto flex-wrap">
          <div className="flex items-center gap-2 px-3.5 py-1.5 bg-[#f0f3ff] rounded-full border border-[#e2e8f8]">
            <span className="w-2.5 h-2.5 rounded-full bg-[#10b981] animate-pulse"></span>
            <span className="text-xs text-[#059669] font-bold">
              الجهاز الرئيسي: متصل ونشط (100%)
            </span>
          </div>

          <button
            onClick={() => openEditModal(devices[0])}
            className="flex items-center gap-2 px-4 py-2 bg-[#1e3a8a] text-white rounded-xl shadow-xs hover:bg-[#00236f] transition-all text-xs font-bold active:scale-95"
          >
            <SlidersHorizontal className="w-4 h-4" />
            <span>إعادة ضبط / ربط الجهاز</span>
          </button>

          <button
            onClick={handleRefresh}
            title="مزامنة السجلات الآن"
            className="w-10 h-10 flex items-center justify-center bg-white text-[#444651] hover:text-[#00236f] rounded-xl shadow-xs border border-[#e2e8f8] hover:bg-[#f0f3ff] transition-all"
          >
            <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin text-[#00236f]' : ''}`} />
          </button>
        </div>
      </div>

      {/* Telemetry Bar & Fast Filters */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-3.5 items-center">
        <div className="md:col-span-8 flex flex-wrap items-center gap-2.5">
          <div className="flex items-center gap-2 bg-white px-3.5 py-2 rounded-xl shadow-xs border border-[#e2e8f8]">
            <CheckCircle2 className="w-4 h-4 text-[#059669]" />
            <span className="text-xs text-[#757682]">الحالة التشغيلية:</span>
            <span className="text-xs font-bold text-[#151c27]">جاهز ومستقر 24/7</span>
          </div>

          <div className="flex items-center gap-2 bg-white px-3.5 py-2 rounded-xl shadow-xs border border-[#e2e8f8]">
            <Cpu className="w-4 h-4 text-[#1e3a8a]" />
            <span className="text-xs text-[#757682]">معرف الجهاز:</span>
            <span className="font-mono font-bold text-[#00236f] text-xs bg-[#e7eefe] px-2 py-0.5 rounded">
              FK-RFID-MASTER-01
            </span>
          </div>

          <div className="flex items-center gap-2 bg-white px-3.5 py-2 rounded-xl shadow-xs border border-[#e2e8f8]">
            <MapPin className="w-4 h-4 text-[#d97706]" />
            <span className="text-xs text-[#757682]">الموقع المعتمد:</span>
            <span className="text-xs font-bold text-[#151c27]">المدخل الرئيسي للمدرسة</span>
          </div>
        </div>

        <div className="md:col-span-4 flex items-center justify-end gap-4 bg-white px-4 py-2 rounded-xl shadow-xs border border-[#e2e8f8]">
          <div className="flex items-center gap-1.5 text-[#444651]">
            <Gauge className="w-4 h-4 text-[#059669]" />
            <span className="text-xs">الاستجابة: <b className="text-[#151c27] font-mono">14ms</b></span>
          </div>
          <div className="flex items-center gap-1.5 text-[#444651]">
            <CheckCircle2 className="w-4 h-4 text-[#fea619]" />
            <span className="text-xs">دقة القراءة: <b className="text-[#151c27] font-mono">99.8%</b></span>
          </div>
        </div>
      </div>

      {/* Device Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {devices.map((device) => (
          <div
            key={device.id}
            className="bg-white rounded-2xl shadow-xs border border-[#e2e8f8] overflow-hidden flex flex-col justify-between hover:shadow-md transition-all"
          >
            <div>
              {/* Card top banner line */}
              <div
                className={`h-2 w-full ${
                  device.isActive ? 'bg-[#10b981]' : 'bg-[#ef4444]'
                }`}
              />

              <div className="p-5 flex flex-col gap-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#f0f3ff] text-[#00236f] flex items-center justify-center">
                      {device.protocol === 'rfid' ? (
                        <Radio className="w-5 h-5" />
                      ) : (
                        <Fingerprint className="w-5 h-5" />
                      )}
                    </div>
                    <div className="flex flex-col">
                      <span className="font-mono text-xs font-bold text-[#00236f]">
                        {device.serial}
                      </span>
                      <span className="text-xs font-bold text-[#151c27] mt-0.5">
                        {device.location}
                      </span>
                    </div>
                  </div>

                  <span
                    className={`text-[11px] font-bold px-2 py-0.5 rounded-full border ${
                      device.isActive
                        ? 'bg-[#ecfdf5] text-[#059669] border-[#bbf7d0]'
                        : 'bg-[#fee2e2] text-[#dc2626] border-[#fecaca]'
                    }`}
                  >
                    {device.isActive ? 'متصل ونشط' : 'متوقف'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 bg-[#f0f3ff]/60 p-3 rounded-xl text-xs">
                  <div>
                    <span className="text-[#757682] block text-[11px]">البروتوكول:</span>
                    <span className="font-bold text-[#151c27]">
                      {device.protocol === 'rfid' ? 'بطاقات RFID / NFC' : 'بصمة الإصبع والوجه'}
                    </span>
                  </div>
                  <div>
                    <span className="text-[#757682] block text-[11px]">عنوان IP:</span>
                    <span className="font-mono font-bold text-[#151c27]">{device.ipAddress}</span>
                  </div>
                  <div>
                    <span className="text-[#757682] block text-[11px]">الاستجابة:</span>
                    <span className="font-mono font-bold text-[#059669]">{device.latency}</span>
                  </div>
                  <div>
                    <span className="text-[#757682] block text-[11px]">آخر نبضة:</span>
                    <span className="font-bold text-[#151c27]">{device.lastHeartbeat}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Actions Footer */}
            <div className="px-5 py-3 bg-[#f0f3ff] border-t border-[#e2e8f8] flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <button
                  onClick={() => pingDevice(device)}
                  className="px-2.5 py-1 rounded-lg bg-white text-[#00236f] font-bold border border-[#e2e8f8] hover:bg-[#e7eefe] transition-colors"
                >
                  فحص Ping
                </button>
                <button
                  onClick={() => openEditModal(device)}
                  className="px-2.5 py-1 rounded-lg bg-white text-[#444651] font-bold border border-[#e2e8f8] hover:bg-[#e2e8f8] transition-colors"
                >
                  إعدادات
                </button>
              </div>

              <button
                onClick={() => toggleDeviceActive(device.id)}
                title={device.isActive ? 'إيقاف مؤقت' : 'تشغيل الجهاز'}
                className={`p-1.5 rounded-lg transition-colors ${
                  device.isActive
                    ? 'text-[#059669] hover:bg-[#fee2e2] hover:text-[#dc2626]'
                    : 'text-[#dc2626] hover:bg-[#ecfdf5] hover:text-[#059669]'
                }`}
              >
                <Power className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Diagnostics helper info banner */}
      <div className="bg-white p-5 rounded-2xl shadow-xs border border-[#e2e8f8] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#e6f8f0] text-[#059669] flex items-center justify-center">
            <Network className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-xs font-bold text-[#151c27]">
              بروتوكول الاتصال المحلي الآمن (Wiegand & TCP/IP)
            </h3>
            <p className="text-[11px] text-[#757682]">
              يتم مزامنة بيانات البصمة والتمرير بتردد مشفر 128-bit AES مع الحفاظ على العمل دون اتصال في حال انقطاع الشبكة.
            </p>
          </div>
        </div>

        <button 
          onClick={handleRefresh}
          className="px-4 py-2 rounded-xl bg-[#f0f3ff] text-[#00236f] text-xs font-bold hover:bg-[#e2e8f8] shrink-0 border border-[#e2e8f8]"
        >
          فحص جاهزية الخوادم
        </button>
      </div>

      {/* MODAL: Configure / Edit Device */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4 animate-in fade-in">
          <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden animate-in zoom-in-95">
            {/* Header */}
            <div className="bg-[#f0f3ff] px-6 py-4 border-b border-[#e2e8f8] flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#1e3a8a] text-white flex items-center justify-center">
                  <Settings2 className="w-5 h-5" />
                </div>
                <div className="flex flex-col">
                  <h3 className="text-base font-bold text-[#00236f]">
                    تعديل بيانات الجهاز: {editingDevice.serial}
                  </h3>
                  <span className="text-xs text-[#757682]">
                    ضبط عنوان الشبكة والبروتوكول لقارئ الحضور الرئيسي بنظام أطفال المستقبل
                  </span>
                </div>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="w-8 h-8 rounded-lg flex items-center justify-center text-[#757682] hover:bg-[#e2e8f8]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleFormSubmit} className="p-6 flex flex-col gap-4 text-xs">
              {/* Serial Number */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27] flex items-center justify-between">
                  <span>الرقم التسلسلي للجهاز (Device Serial Number)</span>
                  <span className="text-[#ef4444]">* إجباري</span>
                </label>
                <input
                  type="text"
                  required
                  dir="ltr"
                  value={serial}
                  onChange={(e) => setSerial(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] font-mono text-xs font-bold text-[#151c27] text-left focus:bg-white focus:outline-none"
                />
                <p className="text-[11px] text-[#757682]">
                  مطبوع خلف الجهاز اللوحي أو على ملصق باركود لوحة التحكم.
                </p>
              </div>

              {/* Location Name */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27] flex items-center justify-between">
                  <span>اسم الموقع / البوابة (Location Name)</span>
                  <span className="text-[#ef4444]">* إجباري</span>
                </label>
                <input
                  type="text"
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] text-xs font-bold text-[#151c27] focus:bg-white focus:outline-none"
                />
              </div>

              {/* Protocol Selection */}
              <div className="flex flex-col gap-1.5">
                <label className="font-bold text-[#151c27]">بروتوكول الربط</label>
                <div className="grid grid-cols-2 gap-3">
                  <label className="flex items-center gap-2 p-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] cursor-pointer hover:bg-[#e7eefe]">
                    <input
                      type="radio"
                      name="protocol"
                      checked={protocol === 'rfid'}
                      onChange={() => setProtocol('rfid')}
                      className="accent-[#1e3a8a]"
                    />
                    <span className="font-bold text-[#151c27]">بطاقات RFID / NFC</span>
                  </label>

                  <label className="flex items-center gap-2 p-3 rounded-xl bg-[#f0f3ff] border border-[#e2e8f8] cursor-pointer hover:bg-[#e7eefe]">
                    <input
                      type="radio"
                      name="protocol"
                      checked={protocol === 'biometric'}
                      onChange={() => setProtocol('biometric')}
                      className="accent-[#1e3a8a]"
                    />
                    <span className="font-bold text-[#151c27]">بصمة إصبع ووجه</span>
                  </label>
                </div>
              </div>

              {/* Active Toggle Switch */}
              <div className="flex items-center justify-between bg-[#f0f3ff] p-3.5 rounded-xl border border-[#e2e8f8]">
                <div className="flex flex-col">
                  <span className="font-bold text-[#151c27]">تفعيل استقبال النبضات الحية</span>
                  <span className="text-[11px] text-[#757682]">
                    عند التعطيل سيتم تجاهل حركات المرور الصادرة من هذا الجهاز
                  </span>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-[#c5c5d3] peer-focus:outline-none rounded-full peer peer-checked:after:-translate-x-full rtl:peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:right-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#1e3a8a]"></div>
                </label>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center justify-end gap-2.5 pt-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 h-10 rounded-xl bg-[#f0f3ff] text-[#444651] font-bold hover:bg-[#e2e8f8]"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-6 h-10 rounded-xl bg-[#1e3a8a] text-white font-bold hover:bg-[#00236f] transition-all flex items-center gap-2 shadow-xs"
                >
                  <Save className="w-4 h-4" />
                  <span>تحديث الجهاز</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Toast */}
      {toastMessage && (
        <div className="fixed bottom-6 left-6 z-50 bg-[#2a313d] text-white px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5">
          <CheckCircle2 className="w-5 h-5 text-[#27c38a]" />
          <span className="text-xs font-bold">{toastMessage}</span>
        </div>
      )}
    </div>
  );
};
