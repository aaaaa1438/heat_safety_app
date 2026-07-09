import 'package:flutter/material.dart';

/// 依使用者在客製化設定裡調整的「按鈕大小」倍率,
/// 動態調整按鈕的內距、文字與圖示大小。
class AppScaledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double scale;
  final bool outlined;

  const AppScaledButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.scale,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = 14.0 * scale;
    final iconSize = 20.0 * scale;
    final padding = EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 16 * scale);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize),
        SizedBox(width: 8 * scale),
        Text(label, style: TextStyle(fontSize: fontSize)),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: padding),
        child: content,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(padding: padding),
      child: content,
    );
  }
}
