import 'package:flutter/material.dart';

/// حوار متجاوب — يقيّد العرض الثابت المطلوب بنسبة من نافذة الشاشة
/// حتى لا يفيض على نوافذ سطح المكتب الصغيرة (كانت 7 حوارات بعرض ثابت
/// 440–740px تنكسر تحت النافذة الأضيق من عرضها).
class ResponsiveDialog {
  ResponsiveDialog._();

  /// عرض آمن: أصغر من [preferredWidth] أو 90% من عرض الشاشة
  static double maxWidth(BuildContext context, double preferredWidth) {
    final screen = MediaQuery.sizeOf(context).width;
    return preferredWidth.clamp(280.0, screen * 0.9);
  }

  /// showDialog جاهز بالقيد
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double preferredWidth = 560,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth(dialogContext, preferredWidth)),
          child: builder(dialogContext),
        ),
      ),
    );
  }
}
