import 'package:flutter/material.dart';

/// IndexedStack كسول — يبني كل تبويب عند أول تفعيله فقط ثم يُبقيه حياً:
/// الفلاتر والترقيم والتمرير تُحفظ بين التنقلات (كانت تُفقد مع إعادة
/// البناء في كل تبديل)، وتكلفة الإقلاع تبقى تبويباً واحداً.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activate();
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عدد الأطفال قد يتغير بتغير الدور — أعد المحاذاة
    if (_activated.length != widget.children.length) {
      _activate();
      return;
    }
    if (oldWidget.index != widget.index && !_activated[widget.index]) {
      setState(() => _activated[widget.index] = true);
    }
  }

  void _activate() {
    _activated = List.filled(widget.children.length, false);
    if (widget.index >= 0 && widget.index < _activated.length) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
