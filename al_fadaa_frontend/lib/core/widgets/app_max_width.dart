import 'package:flutter/material.dart';

/// قيد عرض المحتوى — يمنع تمدد القوائم على الشاشات العريضة كاملةً
/// ويوسّطها (كانت الشاشات الثقيلة تتمدد بلا حد على سطح المكتب).
class AppMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppMaxWidth({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
