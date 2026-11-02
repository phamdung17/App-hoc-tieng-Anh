import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Timer? _splashTimer;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _splashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showWelcome = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _startSurvey() => context.go('/survey');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showWelcome ? _welcomeContent() : _splashContent(),
        ),
      ),
    );
  }

  Widget _splashContent() {
    return Padding(
      key: const ValueKey('splash'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 44),
          const Spacer(),
          const _LingoUpBrand(markSize: 48, wordSize: 32),
          const SizedBox(height: 30),
          _OwlCard(height: 236),
          const SizedBox(height: 28),
          SvgPicture.asset('assets/images/onboarding/loading_dots.svg'),
          const Spacer(),
          const SizedBox(height: 44),
        ],
      ),
    );
  }

  Widget _welcomeContent() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LingoUpBrand(markSize: 38, wordSize: 20),
          const SizedBox(height: 28),
          _OwlCard(height: 254),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5DC),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Cùng học, cùng tiến bộ!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Tiếng Anh mỗi ngày,\n',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: 'tự tin mỗi bước.',
                  style: TextStyle(color: AppColors.primaryDark),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bài học nhỏ, niềm vui lớn. Cùng LingoUp xây thói\nquen và tự tin giao tiếp nhé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          OnboardingPrimaryAction(
            label: 'Bắt đầu ngay',
            onPressed: _startSurvey,
            icon: LucideIcons.arrowRight,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.go('/auth'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.outline, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Tôi đã có tài khoản'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LingoUpBrand extends StatelessWidget {
  const _LingoUpBrand({required this.markSize, required this.wordSize});
  final double markSize;
  final double wordSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(markSize * .29),
            border: Border.all(color: AppColors.outline, width: 1.5),
            boxShadow: const [
              BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
            ],
          ),
          child: Text(
            'L',
            style: TextStyle(
              fontSize: wordSize * .85,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Lingo',
                style: TextStyle(
                  fontSize: wordSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Up',
                style: TextStyle(
                  fontSize: wordSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwlCard extends StatelessWidget {
  const _OwlCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
        ],
      ),
      child: Image.asset(
        'assets/images/onboarding/lingoup_owl.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class OnboardingPrimaryAction extends StatelessWidget {
  const OnboardingPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.outline, offset: Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon!, size: 20, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
