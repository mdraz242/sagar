import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/auth_provider.dart';

const _sceneDuration = 3750.0;
const _markAsset = 'assets/branding/vyparhub_v_mark.png';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static bool _playedThisLaunch = false;

  late final AnimationController _mainController;
  late final AnimationController _ambientController;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3750),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    if (_playedThisLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }

    _playedThisLaunch = true;
    _ambientController.repeat();
    _mainController
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    final auth = ref.read(authProvider);
    context.go(auth == null ? '/login' : '/');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: kDebugMode ? _finish : null,
      child: Scaffold(
        backgroundColor: const Color(0xFF08071D),
        body: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _ambientController]),
            builder: (context, _) {
              final t = _mainController.value;
              final exit = _interval(t, 3150, 3750, Curves.easeInOutCubic);
              return Opacity(
                opacity: 1 - exit,
                child: Transform.scale(
                  scale: 1 + (0.035 * exit),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PremiumScene(progress: _ambientController.value),
                      SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: _ForegroundLogo(
                              time: t,
                              ambient: _ambientController.value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ForegroundLogo extends StatelessWidget {
  const _ForegroundLogo({required this.time, required this.ambient});

  final double time;
  final double ambient;

  @override
  Widget build(BuildContext context) {
    final kicker = _interval(time, 50, 620, Curves.easeOutCubic);
    final left = _interval(time, 100, 800, Curves.easeInOutCubic);
    final right = _interval(time, 350, 1050, Curves.easeInOutCubic);
    final leftDot = _interval(time, 1050, 1450, Curves.elasticOut);
    final rightDot = _interval(time, 1100, 1500, Curves.elasticOut);
    final word = _interval(time, 1200, 1700, Curves.easeOutCubic);
    final pulse = _interval(time, 1500, 1900, Curves.easeOutBack);
    final tagline = _interval(time, 1550, 2150, Curves.easeOutCubic);
    final loading = _interval(time, 2050, 2450, Curves.easeOutCubic);
    final loadingFill = _interval(time, 2050, 3050, Curves.easeInOutCubic);
    final breathing = math.sin(ambient * math.pi * 2) * 0.018;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: kicker,
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - kicker)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Text(
                'Vypar Badhao, Munafa Kamao',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 34),
        Transform.scale(
          scale: 1 + (0.06 * pulse) + breathing,
          child: SizedBox(
            width: 170,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _LogoHalf(isLeft: true, progress: left),
                _LogoHalf(isLeft: false, progress: right),
                _GlowDot(
                  alignment: const Alignment(-0.58, -0.76),
                  color: const Color(0xFF003399),
                  progress: leftDot,
                ),
                _GlowDot(
                  alignment: const Alignment(0.58, -0.76),
                  color: const Color(0xFFFF6600),
                  progress: rightDot,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: word,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - word)),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 41,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
                children: [
                  TextSpan(
                    text: 'Vypar',
                    style: TextStyle(color: Color(0xFF2E6BFF)),
                  ),
                  TextSpan(
                    text: 'Hub',
                    style: TextStyle(color: Color(0xFFFF7A00)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: tagline,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - tagline)),
            child: Text(
              'Makers seh Market tak',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 34),
        Opacity(
          opacity: loading,
          child: SizedBox(
            width: 184,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: loadingFill,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF7A00),
                    ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Tap to skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.34),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoHalf extends StatelessWidget {
  const _LogoHalf({required this.isLeft, required this.progress});

  final bool isLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: progress.clamp(0.0, 1.0),
          child: ClipPath(
            clipper: _LogoHalfClipper(isLeft),
            child: Image.asset(
              _markAsset,
              width: 170,
              height: 144,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoHalfClipper extends CustomClipper<Path> {
  const _LogoHalfClipper(this.isLeft);

  final bool isLeft;

  @override
  Path getClip(Size size) {
    final left = isLeft ? 0.0 : size.width * 0.45;
    final right = isLeft ? size.width * 0.55 : size.width;
    return Path()..addRect(Rect.fromLTRB(left, 0, right, size.height));
  }

  @override
  bool shouldReclip(covariant _LogoHalfClipper oldClipper) {
    return oldClipper.isLeft != isLeft;
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({
    required this.alignment,
    required this.color,
    required this.progress,
  });

  final Alignment alignment;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 15.0 * progress.clamp(0.0, 1.2);
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.48),
                blurRadius: 22,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PremiumScene extends StatelessWidget {
  const _PremiumScene({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final wobble = math.sin(progress * math.pi * 2);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.10, -0.18),
          radius: 1.28,
          colors: [Color(0xFF132D8A), Color(0xFF08071D), Color(0xFF040313)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Orb(
            alignment: Alignment(-0.82 + wobble * 0.04, -0.72),
            color: AppColors.brightBlue,
            size: 180,
            opacity: 0.18,
          ),
          _Orb(
            alignment: Alignment(0.82, -0.18 + wobble * 0.05),
            color: AppColors.orange,
            size: 170,
            opacity: 0.16,
          ),
          _Orb(
            alignment: Alignment(-0.45, 0.76 + wobble * 0.03),
            color: const Color(0xFF8FA0D7),
            size: 128,
            opacity: 0.10,
          ),
          CustomPaint(painter: _ScenePainter(progress)),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity * 0.26),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: 80,
              spreadRadius: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.62);
    final softPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.18);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.74);

    final stars = const [
      Offset(0.16, 0.18),
      Offset(0.82, 0.16),
      Offset(0.73, 0.30),
      Offset(0.22, 0.39),
      Offset(0.88, 0.60),
      Offset(0.11, 0.64),
    ];
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final twinkle = 0.55 + 0.45 * math.sin((progress * 2 * math.pi) + i);
      canvas.drawCircle(
        Offset(size.width * s.dx, size.height * s.dy),
        1.3 + twinkle,
        starPaint
          ..color = Colors.white.withValues(alpha: 0.34 + twinkle * 0.34),
      );
    }

    final roadY = size.height - 86;
    canvas.drawLine(
      Offset(size.width * 0.08, roadY),
      Offset(size.width * 0.92, roadY),
      softPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, roadY + 16),
      Offset(size.width * 0.78, roadY + 16),
      softPaint..color = Colors.white.withValues(alpha: 0.10),
    );

    final store = Rect.fromLTWH(28, roadY - 82, 106, 68);
    canvas.drawRRect(
      RRect.fromRectAndRadius(store, const Radius.circular(10)),
      softPaint,
    );
    for (var i = 0; i < 4; i++) {
      final x = store.left + 14 + i * 22;
      canvas.drawLine(
        Offset(x, store.top + 8),
        Offset(x + 12, store.top + 8),
        accentPaint..color = const Color(0xFFFF7A00).withValues(alpha: 0.46),
      );
      canvas.drawLine(
        Offset(x + 6, store.top + 8),
        Offset(x + 6, store.top + 22),
        softPaint..color = Colors.white.withValues(alpha: 0.14),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(store.left + 70, store.top + 34, 22, 34),
      softPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(store.left + 14, store.top + 34, 38, 20),
      softPaint,
    );

    final bikeProgress = progress < 0.58
        ? Curves.easeInOut.transform(progress / 0.58) * 0.66
        : progress < 0.72
            ? 0.66
            : 0.66 +
                Curves.easeInOut.transform((progress - 0.72) / 0.28) * 0.34;
    final bikeX = -68 + (size.width + 136) * bikeProgress;
    final bikeY = roadY - 26;
    _drawBike(canvas, Offset(bikeX, bikeY));
  }

  void _drawBike(Canvas canvas, Offset origin) {
    final bikePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.76);
    final orange = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.86);
    final glow = Paint()
      ..color = const Color(0xFFFFD49A).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(origin + const Offset(16, 28), 10, bikePaint);
    canvas.drawCircle(origin + const Offset(54, 28), 10, bikePaint);
    canvas.drawPath(
      Path()
        ..moveTo(origin.dx + 16, origin.dy + 28)
        ..lineTo(origin.dx + 30, origin.dy + 8)
        ..lineTo(origin.dx + 43, origin.dy + 28)
        ..lineTo(origin.dx + 54, origin.dy + 28)
        ..moveTo(origin.dx + 30, origin.dy + 8)
        ..lineTo(origin.dx + 50, origin.dy + 8)
        ..lineTo(origin.dx + 62, origin.dy + 18),
      orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 20, origin.dy - 7, 28, 14),
        const Radius.circular(4),
      ),
      bikePaint,
    );
    canvas.drawCircle(origin + const Offset(68, 13), 18, glow);
    canvas.drawLine(
        origin + const Offset(62, 13), origin + const Offset(82, 10), orange);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

double _interval(double t, int startMs, int endMs, Curve curve) {
  final start = startMs / _sceneDuration;
  final end = endMs / _sceneDuration;
  final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
  return curve.transform(raw);
}
