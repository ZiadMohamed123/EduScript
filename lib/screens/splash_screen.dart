import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'auth/login_page.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _shimmerController;
  late final AnimationController _revealController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<Offset> _revealSlide;

  bool _overlayVisible = true;
  Widget _basePage = const HomePage();

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _revealSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeOutCubic,
      ),
    );

    _resolveNextPage();
    _startReveal();
  }

  Future<void> _resolveNextPage() async {
    final isLoggedIn = await _checkAuthStatus();
    if (!mounted) return;
    setState(() {
      _basePage = isLoggedIn ? const HomePage() : const LoginPage();
    });
  }

  Future<bool> _checkAuthStatus() async {
    // TODO: Replace with real auth check (tokens/local storage/backend)
    await Future.delayed(const Duration(milliseconds: 150));
    return false;
  }

  Future<void> _startReveal() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _revealController.forward().whenComplete(() {
      if (mounted) {
        setState(() {
          _overlayVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _basePage,
          if (_overlayVisible)
            SlideTransition(
              position: _revealSlide,
              child: _SplashContent(
                bgController: _bgController,
                ringController: _ringController,
                pulseController: _pulseController,
                shimmerController: _shimmerController,
                logoScale: _logoScale,
                logoFade: _logoFade,
                textFade: _textFade,
                textSlide: _textSlide,
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  final AnimationController bgController;
  final AnimationController ringController;
  final AnimationController pulseController;
  final AnimationController shimmerController;
  final Animation<double> logoScale;
  final Animation<double> logoFade;
  final Animation<double> textFade;
  final Animation<Offset> textSlide;

  const _SplashContent({
    required this.bgController,
    required this.ringController,
    required this.pulseController,
    required this.shimmerController,
    required this.logoScale,
    required this.logoFade,
    required this.textFade,
    required this.textSlide,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorTween(
                  begin: AppColors.primary,
                  end: AppColors.primaryDark,
                ).evaluate(bgController)!,
                ColorTween(
                  begin: AppColors.primaryDark,
                  end: AppColors.primaryDark.withOpacity(0.9),
                ).evaluate(bgController)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(
        child: Stack(
          children: [
            _FloatingBlobs(animation: bgController),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.blur_on,
                  size: 42,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.blur_on,
                  size: 52,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: ringController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: ringController.value * 2 * math.pi,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.22),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ScaleTransition(
                        scale: logoScale,
                        child: FadeTransition(
                          opacity: logoFade,
                          child: AnimatedBuilder(
                            animation: shimmerController,
                            builder: (context, child) {
                              final shimmerPos = shimmerController.value;
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      begin: Alignment(-1 + shimmerPos * 2, 0),
                                      end: Alignment(1 + shimmerPos * 2, 0),
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.8),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.35, 0.5, 0.65],
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.srcATop,
                                  child: const Icon(
                                    Icons.document_scanner,
                                    size: 96,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: pulseController,
                        builder: (context, child) {
                          final pulse =
                              1 + 0.04 * math.sin(pulseController.value * 2 * math.pi);
                          return Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: textFade,
                    child: SlideTransition(
                      position: textSlide,
                      child: Column(
                        children: [
                          const Text(
                            'EduScript',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transform your notes into study materials',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  FadeTransition(
                    opacity: textFade,
                    child: Text(
                      'Loading your workspace...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnimatedDots(controller: pulseController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBlobs extends StatelessWidget {
  final Animation<double> animation;

  const _FloatingBlobs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value * 2 * math.pi;
        return Stack(
          children: [
            _blob(
              left: 40 + 10 * math.sin(t),
              top: 120 + 12 * math.cos(t * 1.2),
              size: 90,
              opacity: 0.08,
            ),
            _blob(
              right: 50 + 8 * math.cos(t * 0.8),
              top: 200 + 14 * math.sin(t * 1.1),
              size: 70,
              opacity: 0.07,
            ),
            _blob(
              left: 80 + 12 * math.cos(t * 0.9),
              bottom: 140 + 10 * math.sin(t * 1.3),
              size: 110,
              opacity: 0.06,
            ),
          ],
        );
      },
    );
  }

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(opacity),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity = (value + delay) % 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: 0.3 + 0.7 * opacity,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
