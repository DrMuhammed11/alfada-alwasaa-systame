class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Admin & Analytics
  static const String adminAnalytics = '$baseUrl/admin/analytics';
  static const String adminOrphans = '$baseUrl/admin/orphans';
  static const String adminWorkflows = '$baseUrl/admin/workflows';
  static const String resendFailedMails = '$baseUrl/admin/resend-failed-mails';

  // Management
  static const String departments = '$baseUrl/departments';
  static const String users = '$baseUrl/users';
  static const String audit = '$baseUrl/audit';

  // Demo Credentials for Quick Admin Login
  static const Map<String, String> demoAccounts = {
    'ADMIN': 'admin@al-fadaa.com',
    'GM': 'gm@al-fadaa.com',
    'DEPUTY_GM': 'deputy@al-fadaa.com',
  };

  static const String defaultPassword = 'Alfadaa@2026';

  // Role Names in Arabic
  static String getRoleName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'مدير النظام (Admin)';
      case 'GM':
        return 'المدير العام';
      case 'DEPUTY_GM':
        return 'نائب المدير العام';
      case 'DEPT_MANAGER':
        return 'مدير إدارة';
      case 'EMPLOYEE':
        return 'موظف تنفيذي';
      default:
        return role;
    }
  }
}
