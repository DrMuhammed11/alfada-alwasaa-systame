import 'package:flutter/material.dart';
import '../../../models/correspondence_model.dart';
import 'master_list_item.dart';

class MasterListPane extends StatelessWidget {
  final List<Correspondence> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMorePages;
  final int totalItems;
  final Correspondence? selectedItem;
  final String selectedStatus;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final Function(String) onStatusChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onRefresh;
  final Function(Correspondence) onSelectItem;

  const MasterListPane({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMorePages,
    required this.totalItems,
    required this.selectedItem,
    required this.selectedStatus,
    required this.searchController,
    required this.scrollController,
    required this.onStatusChanged,
    required this.onSearchSubmitted,
    required this.onRefresh,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // شريط البحث وفلاتر الحالة
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث في الموضوع، الاسم، أو البريد...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                searchController.clear();
                                onSearchSubmitted();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (_) => onSearchSubmitted(),
                  ),
                ),
                const SizedBox(height: 10),

                // فلاتر الحالة
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('الكل', 'ALL'),
                      _buildStatusChip('مستلمة', 'RECEIVED'),
                      _buildStatusChip('قيد الإجراء', 'IN_PROGRESS'),
                      _buildStatusChip('محالة', 'REFERRED'),
                      _buildStatusChip('مغلقة', 'CLOSED'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // عداد المعاملات وزر التحديث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'المحادثات ($totalItems)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'تحديث القائمة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // قائمة المعاملات مع التمرير اللانهائي ومؤثر الهيكل العظمي (Skeleton)
          Expanded(
            child: isLoading
                ? _buildSkeletonList()
                : items.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد محادثات مطابقة',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      )
                    : Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: items.length + (hasMorePages ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            final item = items[index];
                            final isSelected = selectedItem?.id == item.id;
                            return MasterListItemTile(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => onSelectItem(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 100, height: 12, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
                      const Spacer(),
                      Container(width: 40, height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 180, height: 11, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 120, height: 9, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF0F172A),
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (selected) {
          if (selected) {
            onStatusChanged(value);
          }
        },
      ),
    );
  }
}
