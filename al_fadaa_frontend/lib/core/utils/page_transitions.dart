import 'package:flutter/material.dart';

/// تأثير انتقال سلس ومهني للصفحات يدعم الاتجاه من اليمين لليسار (RTL)
class EnterprisePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  EnterprisePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // انحناء الحركة بنعومة طبيعية
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // انزلاق خفيف (5%) مع تلاشي الألفة
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
