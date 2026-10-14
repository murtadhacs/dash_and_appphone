export type NavigationTab = 'dashboard' | 'students' | 'attendance' | 'devices' | 'settings' | 'login';

export interface Student {
  id: string;
  code: string;
  name: string;
  grade: string;
  section: string;
  rfidTag: string;
  parentName: string;
  parentRelation: string;
  parentPhone: string;
  pickupPin: string;
  avatarUrl?: string;
  enrollmentDate: string;
  status: 'present' | 'absent' | 'excused';
}

export interface AttendanceRecord {
  id: string;
  studentId: string;
  studentName: string;
  grade: string;
  section: string;
  time: string;
  date: string;
  status: 'present' | 'absent' | 'excused';
  notes: string;
  avatarUrl?: string;
  method?: 'rfid' | 'fingerprint' | 'facial' | 'manual';
  excuseType?: string;
  attachmentUrl?: string;
}

export interface DeviceInfo {
  id: string;
  serial: string;
  location: string;
  protocol: 'rfid' | 'biometric';
  status: 'online' | 'warning' | 'offline';
  latency: string;
  accuracy: string;
  lastHeartbeat: string;
  isActive: boolean;
  ipAddress: string;
}

export interface SchoolSettings {
  schoolName: string;
  whatsappNumber: string;
  supportEmail: string;
  openGateTime: string;
  lateTimeThreshold: string;
  notifyParentSwitch: boolean;
}
