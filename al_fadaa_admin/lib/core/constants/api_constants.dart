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

  // المراسلات (نطاق رؤية الإدارة العليا: الكل)
  static const String correspondences = '$baseUrl/correspondences';

  // محتوى الموقع الإلكتروني (إدارة)
  static const String siteContentManage = '$baseUrl/site-content/manage';
  static String siteContentKind(String kind) => '$siteContentManage/$kind';
  static String siteContentKindId(String kind, String id) => '$siteContentManage/$kind/$id';
  static String siteContentSetting(String key) => '$siteContentManage/settings/$key';

  // وضع العرض التجريبي — يُفعَّل وقت البناء فقط: --dart-define=DEMO_MODE=true
  // لا تُضمَّن أي بيانات دخول في نسخة الإنتاج
  static const bool isDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  // بريدات العرض التجريبي — كلمة المرور تُقرأ من define وقت البناء ولا تُخزَّن في الكود
  static const List<String> demoAccounts = [
    'admin@al-fadaa.com',
    'gm@al-fadaa.com',
  ];
  static const String demoPassword = String.fromEnvironment('DEV_PASSWORD', defaultValue: '');

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
