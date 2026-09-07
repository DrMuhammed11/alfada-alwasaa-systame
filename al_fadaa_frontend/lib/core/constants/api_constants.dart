class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Correspondences
  static const String correspondences = '$baseUrl/correspondences';
  static const String incomingCorrespondences = '$baseUrl/correspondences/incoming';
  static const String internalCorrespondences = '$baseUrl/correspondences/internal';

  // System
  static const String departments = '$baseUrl/departments';
  static const String users = '$baseUrl/users';
  static const String audit = '$baseUrl/audit';
  static const String tasks = '$baseUrl/tasks';
  static const String referrals = '$baseUrl/referrals/my';

  // Demo Credentials
  static const Map<String, String> demoAccounts = {
    'ADMIN': 'admin@al-fadaa.com',
    'GM': 'gm@al-fadaa.com',
    'DEPUTY_GM': 'deputy@al-fadaa.com',
    'DEPT_MANAGER': 'eng.manager@al-fadaa.com',
    'EMPLOYEE': 'eng.employee1@al-fadaa.com',
    'FINANCE': 'fin.manager@al-fadaa.com',
    'RECEPTION': 'reception@al-fadaa.com',
    'CUSTOMER_SERVICE': 'cs.manager@al-fadaa.com',
  };

  static const String defaultPassword = 'Alfadaa@2026';

  // Roles Arabic Names
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

  // Priority Arabic & Colors
  static String getPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return 'عاجل جداً';
      case 'HIGH':
        return 'مرتفع';
      case 'NORMAL':
        return 'عادي';
      case 'LOW':
        return 'منخفض';
      default:
        return priority;
    }
  }

  // Status Arabic Labels
  static String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return 'مستلمة';
      case 'UNDER_REVIEW':
        return 'قيد المراجعة';
      case 'REFERRED':
        return 'محالة';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'PENDING_APPROVAL':
        return 'بانتظار الاعتماد';
      case 'APPROVED':
        return 'معتمدة';
      case 'SENT':
        return 'مرسلة';
      case 'CLOSED':
        return 'مغلقة';
      case 'ARCHIVED':
        return 'مؤرشفة';
      default:
        return status;
    }
  }

  // Type Arabic Labels
  static String getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'INCOMING':
        return 'واردة';
      case 'OUTGOING':
        return 'صادرة';
      case 'INTERNAL':
        return 'داخلي';
      default:
        return type;
    }
  }
}
