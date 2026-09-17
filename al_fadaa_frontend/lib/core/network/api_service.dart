import 'package:flutter/foundation.dart';
import '../../models/correspondence_model.dart';
import '../../models/user_model.dart';
import 'api/auth_api.dart';
import 'api/correspondences_api.dart';
import 'api/departments_api.dart';
import 'api/notifications_api.dart';
import 'api/referrals_api.dart';
import 'api/replies_api.dart';
import 'api/system_api.dart';
import 'api/tasks_api.dart';
import 'api/users_api.dart';
import 'session_manager.dart';

export 'session_manager.dart' show UnauthorizedException;

/// واجهة موحدة (Facade) تجمع كافة خدمات واستدعاءات الشبكة مع الحفاظ على التوافق الخلفي التام
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SessionManager _session = SessionManager();
  final AuthApi _auth = AuthApi();
  final CorrespondencesApi _correspondences = CorrespondencesApi();
  final RepliesApi _replies = RepliesApi();
  final TasksApi _tasks = TasksApi();
  final ReferralsApi _referrals = ReferralsApi();
  final NotificationsApi _notifications = NotificationsApi();
  final SystemApi _system = SystemApi();
  final UsersApi _users = UsersApi();
  final DepartmentsApi _departments = DepartmentsApi();

  // --- Session ---
  Future<void> init() => _session.init();
  Future<void> saveToken(String token) => _session.saveToken(token);
  Future<void> clearToken() => _session.clearToken();
  String? get token => _session.token;
  String get sseNotificationsUrl => _notifications.sseNotificationsUrl;

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) =>
      _auth.login(email, password);

  Future<User?> getMe({Duration timeout = const Duration(seconds: 10)}) =>
      _auth.getMe(timeout: timeout);

  // --- Correspondences ---
  Future<Map<String, dynamic>> getCorrespondencesPaginated({
    String? type,
    String? status,
    String? priority,
    String? channel,
    String? search,
    int page = 1,
    int limit = 20,
  }) =>
      _correspondences.getCorrespondencesPaginated(
        type: type,
        status: status,
        priority: priority,
        channel: channel,
        search: search,
        page: page,
        limit: limit,
      );

  Future<Map<String, dynamic>> searchCorrespondences({
    String? q,
    String? type,
    String? status,
    String? priority,
    String? departmentId,
    String? from,
    String? to,
    bool? hasAttachments,
    int page = 1,
    int limit = 20,
  }) =>
      _correspondences.searchCorrespondences(
        q: q,
        type: type,
        status: status,
        priority: priority,
        departmentId: departmentId,
        from: from,
        to: to,
        hasAttachments: hasAttachments,
        page: page,
        limit: limit,
      );

  Future<Map<String, dynamic>?> getCorrespondenceLineage(String id) =>
      _correspondences.getLineage(id);

  Future<List<Correspondence>> getCorrespondences({
    String? type,
    String? status,
    String? priority,
    String? search,
    int page = 1,
    int limit = 20,
  }) =>
      _correspondences.getCorrespondences(
        type: type,
        status: status,
        priority: priority,
        search: search,
        page: page,
        limit: limit,
      );

  Future<Correspondence?> getCorrespondenceById(String id) =>
      _correspondences.getCorrespondenceById(id);

  Future<Map<String, dynamic>> createIncoming({
    required String subject,
    required String senderName,
    String? senderEmail,
    String? senderPhone,
    String? body,
    String priority = 'NORMAL',
  }) =>
      _correspondences.createIncoming(
        subject: subject,
        senderName: senderName,
        senderEmail: senderEmail,
        senderPhone: senderPhone,
        body: body,
        priority: priority,
      );

  Future<Map<String, dynamic>> createInternal({
    required String subject,
    required String body,
    String priority = 'NORMAL',
  }) =>
      _correspondences.createInternal(
        subject: subject,
        body: body,
        priority: priority,
      );

  Future<Map<String, dynamic>> referCorrespondence(
    String correspondenceId, {
    required String toUserId,
    String? note,
    String? dueDate,
  }) =>
      _correspondences.referCorrespondence(
        correspondenceId,
        toUserId: toUserId,
        note: note,
        dueDate: dueDate,
      );

  Future<Map<String, dynamic>> createTask(
    String correspondenceId, {
    required String title,
    String? description,
    required String assignedToId,
    String? dueDate,
  }) =>
      _correspondences.createTask(
        correspondenceId,
        title: title,
        description: description,
        assignedToId: assignedToId,
        dueDate: dueDate,
      );

  Future<Map<String, dynamic>> updateCorrespondenceStatus(String correspondenceId, String status) =>
      _correspondences.updateCorrespondenceStatus(correspondenceId, status);

  Future<Map<String, dynamic>> closeCorrespondence(String id) =>
      _correspondences.closeCorrespondence(id);

  Future<Map<String, dynamic>> archiveCorrespondence(String id) =>
      _correspondences.archiveCorrespondence(id);

  // --- Replies ---
  Future<Map<String, dynamic>> createReply(String correspondenceId, String content) =>
      _replies.createReply(correspondenceId, content);

  Future<Map<String, dynamic>> updateReply(String replyId, String content) =>
      _replies.updateReply(replyId, content);

  Future<Map<String, dynamic>> sendDirectReply(
    String correspondenceId,
    String body, [
    List<String>? attachmentIds,
  ]) =>
      _replies.sendDirectReply(correspondenceId, body, attachmentIds);

  Future<Map<String, dynamic>> submitReply(String replyId) =>
      _replies.submitReply(replyId);

  Future<Map<String, dynamic>> approveReply(String replyId) =>
      _replies.approveReply(replyId);

  Future<Map<String, dynamic>> rejectReply(String replyId, String note) =>
      _replies.rejectReply(replyId, note);

  Future<Map<String, dynamic>> sendReply(String replyId) =>
      _replies.sendReply(replyId);

  Future<List<ReplyVersionItem>> getReplyVersions(String replyId) =>
      _replies.getReplyVersions(replyId);

  Future<DiffResult?> getReplyDiff(String replyId, {int? v1, int? v2}) =>
      _replies.getReplyDiff(replyId, v1: v1, v2: v2);

  // --- Tasks & Referrals ---
  Future<List<TaskItem>> getMyTasks() => _tasks.getMyTasks();
  Future<List<TaskItem>> getAllTasks() => _tasks.getAllTasks();
  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    String status, {
    String? completionNote,
  }) =>
      _tasks.updateTaskStatus(taskId, status, completionNote: completionNote);

  Future<List<ReferralItem>> getMyReferrals() => _referrals.getMyReferrals();

  // --- Notifications ---
  Future<List<Map<String, dynamic>>> getMyNotifications({bool unreadOnly = false}) =>
      _notifications.getMyNotifications(unreadOnly: unreadOnly);

  Future<int> getUnreadNotificationsCount() =>
      _notifications.getUnreadNotificationsCount();

  Future<bool> markNotificationAsRead(String id) =>
      _notifications.markNotificationAsRead(id);

  Future<bool> markAllNotificationsAsRead() =>
      _notifications.markAllNotificationsAsRead();

  // --- System & Delegations ---
  Future<List<Department>> getDepartments() => _system.getDepartments();
  Future<List<User>> getUsers() => _system.getUsers();
  Future<List<Map<String, dynamic>>> getAuditLogs() => _system.getAuditLogs();
  Future<Map<String, dynamic>> syncMail() => _system.syncMail();

  Future<List<Map<String, dynamic>>> getMyDelegations() =>
      _system.getMyDelegations();

  Future<Map<String, dynamic>> createDelegation({
    required String delegateId,
    required DateTime startDate,
    required DateTime endDate,
    String? note,
  }) =>
      _system.createDelegation(
        delegateId: delegateId,
        startDate: startDate,
        endDate: endDate,
        note: note,
      );

  Future<Map<String, dynamic>> terminateDelegation(String delegationId) =>
      _system.terminateDelegation(delegationId);

  // --- Attachments ---
  Future<Map<String, dynamic>> uploadCorrespondenceAttachment(
    String correspondenceId,
    Uint8List bytes,
    String filename,
  ) =>
      _system.uploadCorrespondenceAttachment(correspondenceId, bytes, filename);

  Future<Map<String, dynamic>> uploadReplyAttachment(
    String replyId,
    Uint8List bytes,
    String filename,
  ) =>
      _system.uploadReplyAttachment(replyId, bytes, filename);

  Future<Uint8List?> getAttachmentBytes(String attachmentId) =>
      _system.getAttachmentBytes(attachmentId);

  Future<bool> viewAttachment(String attachmentId, String fileName, [String? mimeType]) =>
      _system.viewAttachment(attachmentId, fileName, mimeType);

  Future<bool> downloadAttachment(String attachmentId, String fileName) =>
      _system.downloadAttachment(attachmentId, fileName);

  // --- Users & Permissions ---
  Future<Map<String, dynamic>> getUsersPaginated({
    String? role,
    String? departmentId,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) =>
      _users.getUsersPaginated(
        role: role,
        departmentId: departmentId,
        isActive: isActive,
        page: page,
        limit: limit,
      );

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? jobTitle,
    String? employeeNumber,
    String? phone,
  }) =>
      _users.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        departmentId: departmentId,
        jobTitle: jobTitle,
        employeeNumber: employeeNumber,
        phone: phone,
      );

  Future<Map<String, dynamic>> updateUser(
    String id, {
    String? name,
    String? email,
    String? password,
    String? role,
    String? departmentId,
    String? jobTitle,
    String? employeeNumber,
    String? phone,
    bool? isActive,
  }) =>
      _users.updateUser(
        id,
        name: name,
        email: email,
        password: password,
        role: role,
        departmentId: departmentId,
        jobTitle: jobTitle,
        employeeNumber: employeeNumber,
        phone: phone,
        isActive: isActive,
      );

  Future<Map<String, dynamic>> deactivateUser(String id) =>
      _users.deactivateUser(id);

  // --- Departments / Sectors ---
  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
    String? managerId,
  }) =>
      _departments.createDepartment(name: name, code: code, managerId: managerId);

  Future<Map<String, dynamic>> updateDepartment(
    String id, {
    String? name,
    String? code,
    String? managerId,
  }) =>
      _departments.updateDepartment(id, name: name, code: code, managerId: managerId);

  Future<Map<String, dynamic>> deleteDepartment(String id) =>
      _departments.deleteDepartment(id);
}
