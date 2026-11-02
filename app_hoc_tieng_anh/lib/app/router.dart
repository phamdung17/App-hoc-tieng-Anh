// lib/app/router.dart
//
// Định nghĩa tất cả routes dùng go_router.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/onboarding_survey_page.dart';
import '../features/auth/presentation/pages/email_verification_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/password_recovery_page.dart';
import '../features/learning/domain/lesson_models.dart';
import '../features/learning/presentation/pages/learning_path_page.dart';
import '../features/learning/presentation/pages/lesson_page.dart';
import '../features/learning/presentation/pages/lesson_result_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/review/presentation/pages/review_page.dart';
import '../features/scan/domain/scan_models.dart';
import '../features/scan/presentation/pages/scan_camera_page.dart';
import '../features/scan/presentation/pages/scan_result_page.dart';
import '../features/vocabulary/presentation/pages/vocabulary_page.dart';
import '../features/vocabulary/domain/vocabulary_word.dart';
import '../features/vocabulary/presentation/pages/vocabulary_detail_page.dart';

// ── Route names (constants để tránh typo) ────────────────────────────────────

class AppRoutes {
  AppRoutes._();

  static const welcome = '/welcome';
  static const survey = '/survey';
  static const auth = '/auth';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const flashcards = '/flashcards';
  static const home = '/home';
  static const learning = '/home/learning';
  static const vocabulary = '/home/vocabulary';
  static const review = '/home/review';
  static const profile = '/home/profile';
  static const scan = '/scan';
  static const scanResult = '/scan-result';
  static const wordDetail = '/word/:id';
  static const lessonDetail = '/lesson/:id';
  static const lessonResult = '/lesson-result';
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    routes: [
      // Welcome / Splash
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),

      // Onboarding survey
      GoRoute(
        path: AppRoutes.survey,
        name: 'survey',
        builder: (context, state) => const OnboardingSurveyPage(),
      ),

      // Auth (login / register tabs)
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const PasswordRecoveryPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) =>
            PasswordRecoveryPage(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: AppRoutes.flashcards,
        name: 'flashcards',
        builder: (context, state) => const ReviewPage(),
      ),

      // Email verification
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => EmailVerificationPage(
          email: state.extra is String
              ? state.extra! as String
              : state.uri.queryParameters['email'],
          token: state.uri.queryParameters['token'],
        ),
      ),

      // AI Scan (full-screen, không thuộc shell)
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) => const ScanCameraPage(),
      ),

      GoRoute(
        path: AppRoutes.scanResult,
        name: 'scanResult',
        builder: (context, state) {
          final result = state.extra as ScanResult?;
          if (result == null) {
            return const ScanCameraPage();
          }
          return ScanResultPage(result: result);
        },
      ),

      // Word detail
      GoRoute(
        path: AppRoutes.wordDetail,
        name: 'wordDetail',
        builder: (context, state) {
          final wordId = state.pathParameters['id'] ?? '';
          final word = state.extra is VocabularyWord
              ? state.extra! as VocabularyWord
              : null;
          return VocabularyDetailPage(wordId: wordId, word: word);
        },
      ),

      // Lesson detail
      GoRoute(
        path: AppRoutes.lessonDetail,
        name: 'lessonDetail',
        builder: (context, state) {
          final lessonId = state.pathParameters['id'] ?? 'unit1_lesson2';
          return LessonPage(lessonId: lessonId);
        },
      ),

      // Lesson result
      GoRoute(
        path: AppRoutes.lessonResult,
        name: 'lessonResult',
        builder: (context, state) {
          final result = state.extra as LessonResult?;
          if (result == null) {
            return const LearningPathPage();
          }
          return LessonResultPage(result: result);
        },
      ),

      // Home shell với 4 tabs
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.learning,
            name: 'learning',
            builder: (context, state) => const LearningPathPage(),
          ),
          GoRoute(
            path: AppRoutes.vocabulary,
            name: 'vocabulary',
            builder: (context, state) => const VocabularyPage(),
          ),
          GoRoute(
            path: AppRoutes.review,
            name: 'review',
            builder: (context, state) => const ReviewPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}

// ── Main Shell (4 tabs + Camera FAB) ─────────────────────────────────────────

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.learning)) return 0;
    if (location.startsWith(AppRoutes.vocabulary)) return 1;
    if (location.startsWith(AppRoutes.review)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      // Camera FAB nổi bật ở giữa
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.scan),
        backgroundColor: AppColors.primary,
        elevation: 4,
        tooltip: 'Scan vật thể AI',
        child: const Icon(LucideIcons.camera, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.map,
              activeIcon: LucideIcons.map,
              label: 'Lộ trình',
              isActive: currentIndex == 0,
              onTap: () => context.go(AppRoutes.learning),
            ),
            _NavItem(
              icon: LucideIcons.bookOpen,
              activeIcon: LucideIcons.bookOpen,
              label: 'Từ vựng',
              isActive: currentIndex == 1,
              onTap: () => context.go(AppRoutes.vocabulary),
            ),
            const SizedBox(width: 48), // Khoảng trống cho FAB
            _NavItem(
              icon: LucideIcons.repeat2,
              activeIcon: LucideIcons.repeat2,
              label: 'Ôn tập',
              isActive: currentIndex == 2,
              onTap: () => context.go(AppRoutes.review),
            ),
            _NavItem(
              icon: LucideIcons.userRound,
              activeIcon: LucideIcons.userRound,
              label: 'Hồ sơ',
              isActive: currentIndex == 3,
              onTap: () => context.go(AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primaryDark;
    const inactive = AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primary : inactive,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? primary : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
