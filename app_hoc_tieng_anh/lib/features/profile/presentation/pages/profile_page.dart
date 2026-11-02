import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/app_sound_effects.dart';
import '../../../../core/notifications/study_reminder_notifications.dart';
import '../../../../core/network/app_api.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../scan/data/scan_api_service.dart';
import '../widgets/study_reminder_settings_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StudyReminderSchedule _reminderSchedule = const StudyReminderSchedule();
  Map<String, dynamic>? _user;
  ScanQuota? _scanQuota;
  int _savedWords = 0;

  @override
  void initState() {
    super.initState();
    unawaited(AppSoundEffects.instance.initialize());
    unawaited(_loadReminderSchedule());
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      final response = await AppApi.instance.dio.get<Map<String, dynamic>>('/auth/me');
      if (mounted) setState(() => _user = response.data);
    } catch (_) {}
    try {
      final quota = await ScanApiService.instance.getQuota();
      if (mounted) setState(() => _scanQuota = quota);
    } catch (_) {}
    try {
      final words = await ScanApiService.instance.getSavedWords();
      if (mounted) setState(() => _savedWords = words.length);
    } catch (_) {}
  }

  Future<void> _loadReminderSchedule() async {
    final schedule = await StudyReminderNotifications.instance.loadSchedule();
    if (mounted) setState(() => _reminderSchedule = schedule);
  }

  Future<void> _openReminderSettings() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const StudyReminderSettingsSheet(),
    );
    if (saved == true) await _loadReminderSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ học tập',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Image.asset(
                      'assets/images/onboarding/lingoup_owl.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?['display_name'] as String? ?? 'Hồ sơ học tập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _user?['email'] as String? ?? 'Đăng nhập để xem hồ sơ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: LucideIcons.flame,
                    title: '${(_user?['streak_days'] as num?)?.toInt() ?? 0} Ngày',
                    subtitle: 'Chuỗi streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: LucideIcons.zap,
                    title: '${(_user?['xp_total'] as num?)?.toInt() ?? 0} XP',
                    subtitle: 'Tổng kinh nghiệm',
                  ),
                ),
                const SizedBox(width: 12),
                  Expanded(
                  child: _StatTile(
                    icon: LucideIcons.bookOpen,
                      title: '$_savedWords Từ',
                    subtitle: 'Đã tích lũy',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Settings list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      LucideIcons.bellRing,
                      color: AppColors.primary,
                    ),
                    title: const Text('Nhắc nhở học hàng ngày'),
                    subtitle: Text(
                      _reminderSchedule.enabled
                          ? '${_reminderSchedule.timeLabel} ${_reminderSchedule.daysLabel}'
                          : 'Đang tắt',
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: _openReminderSettings,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.volume2,
                      color: AppColors.primary,
                    ),
                    title: const Text('Hiệu ứng âm thanh'),
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: AppSoundEffects.instance.enabled,
                      builder: (context, isEnabled, _) => Switch(
                        value: isEnabled,
                        onChanged: AppSoundEffects.instance.setEnabled,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.primary,
                    ),
                    title: const Text('Hạn mức Gemini AI Scan'),
                    subtitle: Text(_scanQuota == null
                        ? 'Đăng nhập để xem hạn mức'
                        : '${_scanQuota!.remaining}/${_scanQuota!.limit} lượt còn hôm nay'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: _loadProfile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await AppApi.instance.clearTokens();
                if (context.mounted) context.go(AppRoutes.auth);
              },
              icon: const Icon(LucideIcons.logOut, color: AppColors.error),
              label: const Text('Đăng xuất / Chuyển tài khoản'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryDark),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
