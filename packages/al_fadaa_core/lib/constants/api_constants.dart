import 'package:flutter/material.dart';
import '../theme/brand_theme.dart';

/// ثوابت الـ API الموحدة لشركة الفضاء الواسع — متوافقة 100% مع NestJS Backend
class CoreApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.alfadaalwasaa.com/api/v1',
  );

  static const bool isDevMode = bool.fromEnvironment(
    'DEV_MODE',
    defaultValue: false,
  );

  // ─── المصادقة (Auth) ───
  static const String login          = '$baseUrl/auth/login';
  static const String me             = '$baseUrl/auth/me';
  static const String refresh        = '$baseUrl/auth/refresh';
  static const String logout         = '$baseUrl/auth/logout';
  static const String changePassword = '$baseUrl/auth/change-password';

  // ─── المراسلات والمعاملات (Correspondences) ───
  static const String correspondences         = '$baseUrl/correspondences';
  static const String incomingCorrespondences = '$baseUrl/correspondences/incoming';
  static const String internalCorrespondences = '$baseUrl/correspondences/internal';
  static const String searchCorrespondences   = '$baseUrl/correspondences/search';

  static String correspondenceDetail(String id) => '$correspondences/$id';
  static String correspondenceStatus(String id) => '$correspondences/$id/status';
  static String correspondenceTimeline(String id) => '$correspondences/$id/timeline';
  static String correspondenceReplies(String id) => '$correspondences/$id/replies';
  static String correspondenceAttachments(String id) => '$correspondences/$id/attachments';

  // ─── الإحالات والمهام (Referrals & Tasks) ───
  static const String referrals   = '$baseUrl/referrals';
  static const String myReferrals = '$baseUrl/referrals/my';
  static const String tasks       = '$baseUrl/tasks';

  // ─── النظام والهيكل التنظيمي (Departments & Users) ───
  static const String departments = '$baseUrl/departments';
  static const String users       = '$baseUrl/users';
  static const String delegations = '$baseUrl/delegations';

  // ─── الإشعارات والتدقيق (Notifications & Audit) ───
  static const String notifications       = '$baseUrl/notifications';
  static const String notificationStream  = '$baseUrl/notifications/stream';
  static const String auditLogs           = '$baseUrl/audit';

  // ─── الإدارة العليا والتحليلات (Admin & Analytics) ───
  static const String adminAnalytics     = '$baseUrl/admin/analytics';
  static const String resendFailedMails  = '$baseUrl/admin/resend-failed-mails';
  static const String approvalWorkflows  = '$baseUrl/admin/approval-workflows';

  // ─── إدارة محتوى الموقع (CMS Site Content) ───
  static const String siteContentManage  = '$baseUrl/site-content/manage';
  static String siteContentKind(String kind) => '$siteContentManage/$kind';
  static String siteContentKindId(String kind, String id) => '$siteContentManage/$kind/$id';

  // ════════════════════════════════════════════════════════════════════
  // ─── مترجمات التسميات والألوان والأيقونات (Translators & Helpers) ───
  // ════════════════════════════════════════════════════════════════════

  /// مسميات الأدوار باللغة العربية
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

  /// مسميات درجات الأولوية
  static String getPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return 'عاجل جداً';
      case 'HIGH':
        return 'عاجل';
      case 'NORMAL':
        return 'مهم';
      case 'LOW':
        return 'عادي';
      default:
        return priority;
    }
  }

  /// ألوان درجات الأولوية
  static Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return BrandTheme.crimson;
      case 'HIGH':
        return BrandTheme.amber;
      case 'NORMAL':
        return BrandTheme.sky;
      case 'LOW':
      default:
        return BrandTheme.textTertiary;
    }
  }

  /// مسميات حالات المعاملات
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

  /// ألوان حالات المعاملات
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'CLOSED':
        return BrandTheme.emerald;
      case 'UNDER_REVIEW':
      case 'PENDING_APPROVAL':
      case 'IN_PROGRESS':
        return BrandTheme.amber;
      case 'REFERRED':
        return BrandTheme.purple;
      case 'RECEIVED':
      case 'SENT':
        return BrandTheme.sky;
      case 'ARCHIVED':
      default:
        return BrandTheme.textTertiary;
    }
  }

  /// نوع المراسلة
  static String getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'INCOMING':
        return 'واردة';
      case 'OUTGOING':
        return 'صادرة';
      case 'INTERNAL':
        return 'داخلية';
      default:
        return type;
    }
  }

  /// حالة الإحالة
  static String getReferralStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'قيد المعالجة';
      case 'ANSWERED':
        return 'تم الرد عليها';
      case 'CLOSED':
        return 'مغلقة';
      default:
        return status;
    }
  }
}
