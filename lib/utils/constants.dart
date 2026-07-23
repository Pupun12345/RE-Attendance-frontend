// lib/utils/constants.dart
// ============================================================
//  Single source of truth for all URLs, endpoints & app config
// ============================================================

// ── Base URL ─────────────────────────────────────────────────
// Uncomment the one matching your environment and comment the rest

// 🖥️  Windows / Web / Desktop (local server)
// const String apiBaseUrl = 'http://localhost:5000';

// 📱  Android Emulator
// const String apiBaseUrl = 'http://10.0.2.2:5000';

// 🌐  Production (Google Cloud Run)
const String apiBaseUrl = 'https://re-attendance-backend-264138863806.europe-west1.run.app';
 // const String apiBaseUrl = 'https://mw0p8drn-3000.inc1.devtunnels.ms';
//


// ── API version prefix ───────────────────────────────────────
const String _api = '$apiBaseUrl/api/v1';

// ── Auth endpoints ───────────────────────────────────────────
const String apiLogin = '$_api/auth/login';
const String apiForgotPassword = '$_api/auth/forgotpassword';

// ── User endpoints ───────────────────────────────────────────
const String apiUsers = '$_api/users';
String apiUserById(String id) => '$_api/users/$id';
String apiUserEnable(String id) => '$_api/users/$id/enable';
const String apiWorkers = '$_api/users?role=worker';

// ── Attendance endpoints ─────────────────────────────────────
const String apiAttendancePending = '$_api/attendance/pending';
const String apiAttendanceSummaryToday = '$_api/attendance/summary/today';
const String apiAttendanceStatusToday = '$_api/attendance/status/today';
const String apiCheckin = '$_api/attendance/checkin';
const String apiCheckinPending = '$_api/attendance/checkin-pending';
const String apiCheckout = '$_api/attendance/checkout';
const String apiCheckoutPending = '$_api/attendance/checkout-pending';
const String apiSupervisorCheckin = '$_api/attendance/supervisor/checkin';
const String apiSupervisorCheckinPending = '$_api/attendance/supervisor/checkin-pending';
const String apiSupervisorCheckout = '$_api/attendance/supervisor/checkout';
const String apiSupervisorCheckoutPending = '$_api/attendance/supervisor/checkout-pending';
String apiAttendanceAction(String id, String action) => '$_api/attendance/$id/$action';

// ── Reports endpoints ────────────────────────────────────────
const String apiReportsAttendanceDaily = '$_api/reports/attendance/daily';
String apiAttendanceDailyRange(String startDate, String endDate) =>
    '$apiReportsAttendanceDaily?startDate=$startDate&endDate=$endDate';

// ── Overtime endpoints ───────────────────────────────────────
const String apiOvertime = '$_api/overtime';
String apiOvertimeAction(String id, String action) =>
    '$_api/overtime/$id/$action';

// ── Holiday endpoints ────────────────────────────────────────
const String apiHolidays = '$_api/holidays';
String apiHolidayById(String id) => '$_api/holidays/$id';

// ── Complaints endpoints ─────────────────────────────────────
const String apiComplaints = '$_api/complaints';

// ── External / Static URLs ───────────────────────────────────
const String urlPrivacyPolicy =
    'https://public-document.smartnex.tech/ray-enginerring/attainadnace-app/privacy-policy-playstore';
const String urlWebsite = 'https://www.smartnex.tech/';
