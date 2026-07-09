import 'package:flutter/material.dart';

/// 幾種內建的幾何背景圖案,不需要額外圖片素材,
/// 用 CustomPainter 直接畫,檔案體積小、可換色。
class PatternBackground extends StatelessWidget {
  final String patternId; // 'none' | 'dots' | 'stripes' | 'grid'
  final Color baseColor;
  final Widget? child;

  const PatternBackground({
    super.key,
    required this.patternId,
    required this.baseColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: CustomPaint(
        painter: _PatternPainter(patternId: patternId),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final String patternId;
  _PatternPainter({required this.patternId});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dotPaint = Paint()..color = Colors.black.withValues(alpha: 0.08);

    switch (patternId) {
      case 'dots':
        const spacing = 26.0;
        for (double y = spacing / 2; y < size.height; y += spacing) {
          for (double x = spacing / 2; x < size.width; x += spacing) {
            canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
          }
        }
        break;
      case 'stripes':
        const gap = 22.0;
        for (double x = -size.height; x < size.width; x += gap) {
          canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
        }
        break;
      case 'grid':
        const step = 30.0;
        for (double x = 0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;
      case 'none':
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.patternId != patternId;
}
