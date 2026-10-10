import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/responsive_dialog.dart';

class WorkflowStepsDialog extends StatefulWidget {
  final String priorityLabel;
  final List<String> initialSteps;

  const WorkflowStepsDialog({required this.priorityLabel, required this.initialSteps});

  @override
  State<WorkflowStepsDialog> createState() => WorkflowStepsDialogState();
}

class WorkflowStepsDialogState extends State<WorkflowStepsDialog> {
  static const _roles = {
    'DEPT_MANAGER': 'مدير قسم',
    'DEPUTY_GM': 'نائب المدير العام',
    'GM': 'المدير العام',
    'ADMIN': 'مدير النظام',
  };

  late final List<String> _steps;

  @override
  void initState() {
    super.initState();
    // الاحتفاظ بالأدوار المعروفة فقط وبلا تكرار
    _steps = [
      for (final s in widget.initialSteps)
        if (_roles.containsKey(s.trim().toUpperCase()) && !_steps.contains(s.trim().toUpperCase()))
          s.trim().toUpperCase(),
    ];
  }

  void _toggle(String role) {
    setState(() {
      if (_steps.contains(role)) {
        _steps.remove(role);
      } else {
        _steps.add(role);
      }
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _steps.length) return;
    setState(() => _steps.insert(target, _steps.removeAt(index)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'مسار اعتماد: ${widget.priorityLabel}',
        style: const TextStyle(fontSize: AdminTheme.fontTitle, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: ResponsiveDialog.maxWidth(context, 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر أدوار الاعتماد بالتسلسل — الترتيب المذكور هو ترتيب الموافقة (المستوى 1 أولًا):',
              style: TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted),
            ),
            const SizedBox(height: 10),
            // التسلسل الحالي
            if (_steps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.bgLight,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: const Text(
                  'لم يُختر أي دور بعد — أضف من الأدوار المتاحة أدناه',
                  style: TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
                ),
              )
            else
              for (var i = 0; i < _steps.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface2,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Row(
                    children: [
                      StatusBadge(text: 'م${i + 1}', color: AdminTheme.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _roles[_steps[i]] ?? _steps[i],
                          style: const TextStyle(fontSize: AdminTheme.fontBase, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 15),
                        tooltip: 'رفع مستوى',
                        visualDensity: VisualDensity.compact,
                        onPressed: i > 0 ? () => _move(i, -1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                        tooltip: 'خفض مستوى',
                        visualDensity: VisualDensity.compact,
                        onPressed: i < _steps.length - 1 ? () => _move(i, 1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 15, color: AdminTheme.crimson),
                        tooltip: 'إزالة من المسار',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _toggle(_steps[i]),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            const Text(
              'الأدوار المتاحة — انقر للإضافة أو الإزالة:',
              style: TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in _roles.entries)
                  FilterChip(
                    label: Text(e.value, style: const TextStyle(fontSize: AdminTheme.fontSm)),
                    selected: _steps.contains(e.key),
                    onSelected: (_) => _toggle(e.key),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _steps.isEmpty ? null : () => Navigator.pop(context, List<String>.of(_steps)),
          style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
