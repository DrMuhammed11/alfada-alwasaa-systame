import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/page_transitions.dart';
import '../../models/user_model.dart';
import '../settings/user_tools_screen.dart';
import '../correspondences/create_incoming_dialog.dart';
import '../notifications/notifications_bell.dart';
import 'controllers/dashboard_actions_handler.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'widgets/conversation_detail_pane.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/empty_detail_state.dart';
import 'widgets/master_list_pane.dart';
import 'widgets/mobile_detail_screen.dart';
import 'widgets/sync_status_banner.dart';

/// الشاشة الرئيسية للنظام — مصممة بنظام الأعمدة الثلاثية المتوازنة RTL للشاشات الواسعة ونمط Master-Detail للموبايل
class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardViewModel _vm;
  late final DashboardActionsHandler _actions;
  late final AnimationController _syncIconController;
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = DashboardViewModel(user: widget.user);
    _actions = DashboardActionsHandler(context, _vm);
    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _listScrollController.addListener(_onListScroll);
    _vm.init();
  }

  void _onListScroll() {
    if (_listScrollController.position.pixels >=
        _listScrollController.position.maxScrollExtent - 200) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _detailScrollController.dispose();
    _syncIconController.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    _syncIconController.repeat();
    await _vm.syncMail();
    _syncIconController.stop();
    _syncIconController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user.role.toUpperCase();
    final isAdminOrGM = role == 'ADMIN' || role == 'GM';

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 860;
            final sidebarWidth = _vm.isSidebarCollapsed ? 68.0 : 250.0;

            if (!isWide) {
              return _buildMobileLayout(isAdminOrGM);
            }

            return _buildDesktopLayout(isAdminOrGM, sidebarWidth, isWide, width);
          },
        );
      },
    );
  }

  /// تخطيط الموبايل والشاشات الضيقة (< 860px) بنمط Master-Detail
  Widget _buildMobileLayout(bool isAdminOrGM) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          _getMobileTitle(_vm.selectedNav),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'القائمة الرئيسية',
            onPressed: () => _showMobileSidebar(isAdminOrGM),
          ),
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'أدوات الحساب والرقابة',
            onPressed: () => Navigator.of(context).push(
              EnterprisePageRoute(
                page: UserToolsScreen(user: widget.user, isAdminOrGM: isAdminOrGM),
              ),
            ),
          ),
          IconButton(
            icon: AnimatedBuilder(
              animation: _syncIconController,
              builder: (context, child) => Transform.rotate(
                angle: _syncIconController.value * 2 * math.pi,
                child: const Icon(Icons.sync_rounded, color: Colors.white),
              ),
            ),
            tooltip: 'مزامنة البريد',
            onPressed: _handleSync,
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: MasterListPane(
              items: _vm.items,
              isLoading: _vm.isLoading,
              isLoadingMore: _vm.isLoadingMore,
              hasMorePages: _vm.hasMorePages,
              totalItems: _vm.totalItems,
              selectedItem: _vm.selectedItem,
              selectedStatus: _vm.selectedStatus,
              isWebsiteFilter: _vm.isWebsiteFilter,
              searchController: _vm.searchController,
              scrollController: _listScrollController,
              onStatusChanged: _vm.setStatus,
              onToggleWebsiteFilter: _vm.toggleWebsiteFilter,
              onSearchSubmitted: _vm.fetchCorrespondences,
              onRefresh: () {
                _vm.fetchMyTasks();
                _vm.fetchCorrespondences();
              },
              onSelectItem: (item) {
                _vm.selectItem(item);
                Navigator.of(context).push(
                  EnterprisePageRoute(
                    page: MobileDetailScreen(
                      item: item,
                      vm: _vm,
                      user: widget.user,
                      actions: _actions,
                      detailScrollController: _detailScrollController,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (_) => const CreateIncomingDialog(),
          );
          if (res == true) {
            _vm.fetchCorrespondences();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('وارد جديد'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// تخطيط الشاشات الكبيرة (≥ 860px) بنمط الأعمدة الثلاثية 3-pane
  Widget _buildDesktopLayout(
    bool isAdminOrGM,
    double sidebarWidth,
    bool isWide,
    double width,
  ) {
    final listWidth = width >= 1600 ? 500.0 : (width >= 1350 ? 460.0 : (width >= 1100 ? 420.0 : 380.0));
    final role = widget.user.role.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: Row(
              children: [
                // 1. الشريط الجانبي (Sidebar)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: sidebarWidth,
                  child: DashboardSidebar(
                    user: widget.user,
                    isAdminOrGM: isAdminOrGM,
                    isCollapsed: _vm.isSidebarCollapsed,
                    selectedNav: _vm.selectedNav,
                    totalCount: _vm.items.length,
                    incomingCount: _vm.items.where((i) => i.type == 'INCOMING').length,
                    internalCount: _vm.items.where((i) => i.type == 'INTERNAL').length,
                    outgoingCount: _vm.items.where((i) => i.type == 'OUTGOING').length,
                    myTasksCount: _vm.myTasks.where((t) => !t.isDone).length,
                    isSyncing: _vm.isSyncing,
                    syncIconController: _syncIconController,
                    onToggleCollapse: _vm.toggleSidebar,
                    onSelectNav: _vm.setNav,
                    onOpenCorrespondence: (id) => _vm.fetchCorrespondences(selectId: id),
                    onRefresh: () {
                      _vm.fetchMyTasks();
                      _vm.fetchCorrespondences();
                    },
                    onSyncMail: _handleSync,
                    onLogout: _actions.logout,
                  ),
                ),

                // 2. قائمة المحادثات (Master List Pane)
                SizedBox(
                  width: listWidth,
                  child: MasterListPane(
                    items: _vm.items,
                    isLoading: _vm.isLoading,
                    isLoadingMore: _vm.isLoadingMore,
                    hasMorePages: _vm.hasMorePages,
                    totalItems: _vm.totalItems,
                    selectedItem: _vm.selectedItem,
                    selectedStatus: _vm.selectedStatus,
                    isWebsiteFilter: _vm.isWebsiteFilter,
                    searchController: _vm.searchController,
                    scrollController: _listScrollController,
                    onStatusChanged: _vm.setStatus,
                    onToggleWebsiteFilter: _vm.toggleWebsiteFilter,
                    onSearchSubmitted: _vm.fetchCorrespondences,
                    onRefresh: _vm.fetchCorrespondences,
                    onSelectItem: _vm.selectItem,
                  ),
                ),

                // 3. لوحة تفاصيل المحادثة (Detail Pane)
                Expanded(
                  child: _vm.selectedItem != null
                      ? ConversationDetailPane(
                          selectedItem: _vm.selectedItem,
                          isLoadingDetail: _vm.isLoadingDetail,
                          currentUserId: widget.user.id,
                          role: role,
                          showExtraDetails: _vm.showExtraDetails,
                          isEditing: _vm.editingReplyId != null,
                          isSendingReply: _vm.isSendingReply,
                          quickReplyController: _vm.quickReplyController,
                          detailScrollController: _detailScrollController,
                          pickedFile: _vm.pickedFile,
                          downloadingAttachmentIds: _vm.downloadingAttachmentIds,
                          onToggleExtraDetails: _vm.toggleExtraDetails,
                          onStartReview: _actions.handleStartReview,
                          onClose: _actions.handleClose,
                          onArchive: _actions.handleArchive,
                          onRefresh: () => _vm.fetchCorrespondences(selectId: _vm.selectedItem?.id),
                          onShowDossier: _actions.handleShowDossier,
                          onEditDraft: _vm.startEditingReply,
                          onSubmitReply: _actions.submitReply,
                          onApproveReply: _actions.approveReply,
                          onRejectReply: _actions.rejectReply,
                          onSendReply: _actions.sendReply,
                          onDownloadAttachment: _actions.handleDownloadAttachment,
                          onCancelEdit: _vm.cancelEditingReply,
                          onSaveEdit: _actions.saveEditedReply,
                          onSendDirect: _actions.sendDirectReply,
                          onSaveDraft: _actions.addReply,
                          onPickFile: _vm.pickFile,
                          onRemoveFile: _vm.removeFile,
                        )
                      : const EmptyDetailState(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// عرض القائمة الجانبية في نافذة منبثقة سفلية (BottomSheet Drawer) للموبايل
  void _showMobileSidebar(bool isAdminOrGM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: DashboardSidebar(
            user: widget.user,
            isAdminOrGM: isAdminOrGM,
            isCollapsed: false,
            selectedNav: _vm.selectedNav,
            totalCount: _vm.items.length,
            incomingCount: _vm.items.where((i) => i.type == 'INCOMING').length,
            internalCount: _vm.items.where((i) => i.type == 'INTERNAL').length,
            outgoingCount: _vm.items.where((i) => i.type == 'OUTGOING').length,
            myTasksCount: _vm.myTasks.where((t) => !t.isDone).length,
            isSyncing: _vm.isSyncing,
            syncIconController: _syncIconController,
            onToggleCollapse: () {},
            onSelectNav: _vm.setNav,
            onOpenCorrespondence: (id) => _vm.fetchCorrespondences(selectId: id),
            onRefresh: () {
              _vm.fetchMyTasks();
              _vm.fetchCorrespondences();
            },
            onSyncMail: _handleSync,
            onLogout: _actions.logout,
            onNavigate: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  String _getMobileTitle(String nav) {
    switch (nav.toUpperCase()) {
      case 'INCOMING':
        return 'الوارد العام';
      case 'OUTGOING':
        return 'المراسلات الصادرة';
      case 'INTERNAL':
        return 'الخطابات الداخلية';
      case 'MY_TASKS':
        return 'مهام قطاعي';
      case 'ALL':
      default:
        return 'كل المعاملات';
    }
  }
}
