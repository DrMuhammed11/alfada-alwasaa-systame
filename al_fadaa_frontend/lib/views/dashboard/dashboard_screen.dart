import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'controllers/dashboard_actions_handler.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'widgets/conversation_detail_pane.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/master_list_pane.dart';
import 'widgets/sync_status_banner.dart';

/// الشاشة الرئيسية للنظام — مصممة بنظام الأعمدة الثلاثية المتوازنة RTL
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
            // توازن هندسي محكم للأعمدة الثلاثية: توزيع مدروس للمساحات يمنع انضغاط القائمة ويوازن الشاشة
            final listWidth = isWide
                ? (width >= 1600 ? 500.0 : (width >= 1350 ? 460.0 : (width >= 1100 ? 420.0 : 380.0)))
                : width - sidebarWidth;

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Column(
                children: [
                  const SyncStatusBanner(),
                  Expanded(
                    child: Row(
                      children: [
                        // 1. الشريط الجانبي (Sidebar)
                        SizedBox(
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
                        if (isWide)
                          Expanded(
                            child: ConversationDetailPane(
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
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
