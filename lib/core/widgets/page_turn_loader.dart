import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand loading animation: the RuRead book mark with its right page
/// endlessly turning, used wherever the app would otherwise show a bare
/// spinner (library loading, opening a book, settings/word-bucket loads).
class PageTurnLoader extends StatefulWidget {
  const PageTurnLoader({super.key});

  @override
  State<PageTurnLoader> createState() => _PageTurnLoaderState();
}

class _PageTurnLoaderState extends State<PageTurnLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // First 60% of the loop turns the page 0 -> 180deg (eased); the remaining
  // 40% holds fully turned, then hard-cuts back to 0 on the next loop.
  double _rotationFor(double t) {
    const turnPortion = 0.6;
    final clamped = (t / turnPortion).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(clamped);
    return math.pi * eased;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark mode isn't just a recolor of the same roles - the static base
    // already sits at the resting (blue/red) flag colors and a white page
    // turns over it, landing on blue instead of red turning over white/blue.
    final baseRight = isDark ? const Color(0xFFD52B1E) : Colors.white;
    final pageColor = isDark ? Colors.white : const Color(0xFFD52B1E);
    final inkColor = isDark ? Colors.white : const Color(0xFF1D1C1A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 130,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _rotationFor(_controller.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 130),
                    painter: _BookBasePainter(rightColor: baseRight),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle),
                    child: CustomPaint(
                      size: const Size(160, 130),
                      painter: _PagePainter(color: pageColor),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'RuRead',
          style: GoogleFonts.literata(
            fontWeight: FontWeight.w600,
            fontSize: 40,
            color: inkColor,
          ),
        ),
      ],
    );
  }
}

// Shared geometry: the exact cubic-bezier outline from the app's own SVG
// logo (lib/logo/rureadlogo-256.svg, viewBox 0 0 44 34, spine at x=22).
// Both halves are exact horizontal mirrors of each other around that spine,
// so only the left-half path needs to be defined - the right half and the
// rotating page (which starts over the left half and lands mirrored over
// the right) both reuse it.
Path _leftHalfPath(Size size) {
  const viewWidth = 44.0;
  const viewHeight = 34.0;
  final path = Path()
    ..moveTo(22, 6)
    ..cubicTo(16, 2, 8, 2, 3, 4)
    ..lineTo(3, 28)
    ..cubicTo(8, 26, 16, 26, 22, 30)
    ..close();

  // Fit the viewBox into the given canvas, uniformly scaled and centered -
  // x=22 (the spine) lands exactly on the canvas's horizontal center since
  // 22 is the midpoint of the 44-wide viewBox, which keeps the Transform's
  // Alignment.center rotation hinge aligned with the spine for both the
  // base painter and the rotating page painter below.
  final scale = math.min(size.width / viewWidth, size.height / viewHeight) * 0.86;
  final dx = (size.width - viewWidth * scale) / 2;
  final dy = (size.height - viewHeight * scale) / 2;
  final matrix = Matrix4.identity()
    ..translateByDouble(dx, dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);
  return path.transform(matrix.storage);
}

class _BookBasePainter extends CustomPainter {
  final Color rightColor;
  const _BookBasePainter({required this.rightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final left = _leftHalfPath(size);
    canvas.drawPath(left, Paint()..color = const Color(0xFF0039A6));

    // Right half is the exact mirror of the left - flip the canvas around
    // its vertical center rather than duplicating the path math.
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(left, Paint()..color = rightColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookBasePainter oldDelegate) => oldDelegate.rightColor != rightColor;
}

class _PagePainter extends CustomPainter {
  final Color color;
  const _PagePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Draws only the left-half shape - at rest (0deg) it sits exactly over
    // the base's blue half; rotated 180deg around the shared spine-centered
    // hinge, it appears mirrored, landing on the base's right-colored half.
    canvas.drawPath(_leftHalfPath(size), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PagePainter oldDelegate) => oldDelegate.color != color;
}
