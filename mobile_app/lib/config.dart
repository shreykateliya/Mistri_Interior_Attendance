class Config {
  // CHANGE THIS ONE LINE whenever your IP changes
  static const String baseUrl = "http://192.168.1.3:8000"; 
  
  // API Endpoints
  static const String login = "$baseUrl/api/login/";
  static const String signup = "$baseUrl/api/signup/";
  static const String punchIn = "$baseUrl/api/punch-in/";
  static const String adminDashboard = "$baseUrl/api/admin/dashboard/";
  static const String forceLogout = "$baseUrl/api/admin/force-logout/";
  static const String monthlyReport = "$baseUrl/api/report/monthly/";
  static const String forgotPassword = "$baseUrl/api/forgot-password/";
  static const String resetPassword = "$baseUrl/api/reset-password-confirm/";
  static const String changePassword = "$baseUrl/api/change-password/";
  static const String updateProfilePic = "$baseUrl/api/update-profile-pic/";
}