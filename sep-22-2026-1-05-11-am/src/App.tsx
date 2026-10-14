import React, { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { DashboardView } from './components/DashboardView';
import { StudentsView } from './components/StudentsView';
import { AttendanceView } from './components/AttendanceView';
import { DevicesView } from './components/DevicesView';
import { SettingsView } from './components/SettingsView';
import { LoginView } from './components/LoginView';
import { NavigationTab, Student, AttendanceRecord } from './types';
import { INITIAL_STUDENTS, ATTENDANCE_RECORDS_MASTER } from './data/mockData';

export default function App() {
  const [currentTab, setCurrentTab] = useState<NavigationTab>('dashboard');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  // Global Data State
  const [students, setStudents] = useState<Student[]>(INITIAL_STUDENTS);
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>(ATTENDANCE_RECORDS_MASTER);

  // Cross-view modal shortcuts
  const [openAddStudentShortcut, setOpenAddStudentShortcut] = useState(false);
  const [openLeaveShortcut, setOpenLeaveShortcut] = useState(false);

  const handleAddStudent = (newStudent: Student) => {
    setStudents((prev) => [newStudent, ...prev]);
  };

  const handleUpdateStudent = (updatedStudent: Student) => {
    setStudents((prev) =>
      prev.map((s) => (s.id === updatedStudent.id ? updatedStudent : s))
    );
  };

  const handleDeleteStudent = (studentId: string) => {
    setStudents((prev) => prev.filter((s) => s.id !== studentId));
  };

  const handleAddLeave = (record: AttendanceRecord) => {
    setAttendanceRecords((prev) => [record, ...prev]);
  };

  // Quick Action Handlers from Dashboard
  const handleQuickLeaveFromDashboard = () => {
    setCurrentTab('attendance');
    setOpenLeaveShortcut(true);
  };

  const handleQuickAddStudentFromDashboard = () => {
    setCurrentTab('students');
    setOpenAddStudentShortcut(true);
  };

  // If user clicked Logout or navigated to login
  if (currentTab === 'login') {
    return <LoginView onLoginSuccess={() => setCurrentTab('dashboard')} />;
  }

  return (
    <div className="min-h-screen bg-[#f9f9ff] text-[#151c27] flex font-cairo antialiased">
      {/* Sidebar (Fixed on right for RTL) */}
      <Sidebar
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        mobileOpen={mobileSidebarOpen}
        onCloseMobile={() => setMobileSidebarOpen(false)}
      />

      {/* Main Content Wrap (Padded right on large screens for 256px / 16rem sidebar) */}
      <div className="flex-1 flex flex-col min-w-0 lg:pr-64 min-h-screen">
        {/* Top Header */}
        <Header
          onToggleMobileSidebar={() => setMobileSidebarOpen(!mobileSidebarOpen)}
          onLogout={() => setCurrentTab('login')}
        />

        {/* Dynamic Main Workspace */}
        <main className="flex-1 pt-20 px-4 md:px-8 pb-12 w-full max-w-7xl mx-auto">
          {currentTab === 'dashboard' && (
            <DashboardView
              onNavigate={setCurrentTab}
              onOpenQuickLeave={handleQuickLeaveFromDashboard}
              onOpenAddStudent={handleQuickAddStudentFromDashboard}
            />
          )}

          {currentTab === 'students' && (
            <StudentsView
              students={students}
              onAddStudent={handleAddStudent}
              onUpdateStudent={handleUpdateStudent}
              onDeleteStudent={handleDeleteStudent}
              initialModalOpen={openAddStudentShortcut}
              onCloseInitialModal={() => setOpenAddStudentShortcut(false)}
            />
          )}

          {currentTab === 'attendance' && (
            <AttendanceView
              records={attendanceRecords}
              students={students}
              onAddLeave={handleAddLeave}
              initialLeaveModalOpen={openLeaveShortcut}
              onCloseInitialLeaveModal={() => setOpenLeaveShortcut(false)}
            />
          )}

          {currentTab === 'devices' && <DevicesView />}

          {currentTab === 'settings' && <SettingsView />}
        </main>
      </div>
    </div>
  );
}
