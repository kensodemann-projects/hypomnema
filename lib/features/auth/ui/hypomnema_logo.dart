import 'package:material_ui/material_ui.dart';

class HypomnemaLogo extends StatelessWidget {
  const HypomnemaLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _HypomnemaLogoPainter()),
    );
  }
}

class _HypomnemaLogoPainter extends CustomPainter {
  const _HypomnemaLogoPainter();

  static const _viewBox = 96.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    final bounds = Offset.zero & const Size(_viewBox, _viewBox);
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6E78F0), Color(0xFF3A44B8)],
      ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(22)),
      background,
    );

    canvas.drawPath(_documentPath(), Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(_foldPath(), Paint()..color = const Color(0xFFC9CDFB));

    final rulePaint = Paint()..color = const Color(0xFFC9CDFB);
    for (final rule in _rules) {
      canvas.drawRRect(rule, rulePaint);
    }

    canvas.drawPath(_bookmarkPath(), Paint()..color = const Color(0xFFF2B64C));
  }

  @override
  bool shouldRepaint(covariant _HypomnemaLogoPainter oldDelegate) => false;
}

final _rules = [
  RRect.fromRectAndRadius(Rect.fromLTWH(32, 42, 30, 4), Radius.circular(2)),
  RRect.fromRectAndRadius(Rect.fromLTWH(32, 52, 30, 4), Radius.circular(2)),
  RRect.fromRectAndRadius(Rect.fromLTWH(32, 62, 20, 4), Radius.circular(2)),
];

Path _documentPath() {
  return Path()
    ..moveTo(28, 20)
    ..lineTo(60, 20)
    ..lineTo(72, 32)
    ..lineTo(72, 76)
    ..arcToPoint(const Offset(68, 80), radius: const Radius.circular(4))
    ..lineTo(28, 80)
    ..arcToPoint(const Offset(24, 76), radius: const Radius.circular(4))
    ..lineTo(24, 24)
    ..arcToPoint(const Offset(28, 20), radius: const Radius.circular(4))
    ..close();
}

Path _foldPath() {
  return Path()
    ..moveTo(60, 20)
    ..lineTo(60, 28)
    ..arcToPoint(
      const Offset(64, 32),
      radius: const Radius.circular(4),
      clockwise: false,
    )
    ..lineTo(72, 32)
    ..close();
}

Path _bookmarkPath() {
  return Path()
    ..moveTo(34, 20)
    ..lineTo(46, 20)
    ..lineTo(46, 40)
    ..lineTo(40, 35)
    ..lineTo(34, 40)
    ..close();
}
