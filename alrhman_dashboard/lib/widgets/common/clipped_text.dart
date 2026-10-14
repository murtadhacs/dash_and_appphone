import 'package:flutter/material.dart';

/// نص بعرض أقصى مع قطع بنقاط، وتلميح بالنص الكامل عند المرور.
/// (أسماء الطلاب وأولياء الأمور قد تصل إلى 255 حرفاً.)
class ClippedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double maxWidth;

  const ClippedText(this.text, {super.key, this.style, this.maxWidth = 260});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Tooltip(
        message: text,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
