import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/notifications/study_reminder_notifications.dart';
import '../../../../core/theme/app_theme.dart';

class StudyReminderSettingsSheet extends StatefulWidget {
  const StudyReminderSettingsSheet({super.key});

  @override
  State<StudyReminderSettingsSheet> createState() =>
      _StudyReminderSettingsSheetState();
}

class _StudyReminderSettingsSheetState
    extends State<StudyReminderSettingsSheet> {
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final schedule = await StudyReminderNotifications.instance
          .loadSchedule()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _enabled = schedule.enabled;
        _hour = schedule.hour;
        _minute = schedule.minute;
        _selectedWeekdays = schedule.weekdays;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Không tải được lịch nhắc. Đang dùng lịch mặc định.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'Chọn giờ nhắc học',
    );
    if (time == null || !mounted) return;
    setState(() {
      _hour = time.hour;
      _minute = time.minute;
    });
  }

  Future<void> _save() async {
    if (_enabled && _selectedWeekdays.isEmpty) {
      _showMessage('Chọn ít nhất một ngày để nhận nhắc nhở.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final saved = await StudyReminderNotifications.instance
          .saveSchedule(
            StudyReminderSchedule(
              enabled: _enabled,
              hour: _hour,
              minute: _minute,
              weekdays: _selectedWeekdays,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (!saved) {
        _showMessage(
          'Chưa có quyền thông báo. Hãy bật quyền trong cài đặt thiết bị.',
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _showMessage('Không thể lưu lịch nhắc. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: _isLoading
            ? const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nhắc nhở học tập',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhận thông báo cục bộ vào ngày và giờ bạn chọn.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật nhắc nhở'),
                      subtitle: Text(_enabled ? 'Đang bật' : 'Đang tắt'),
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        LucideIcons.clock3,
                        color: AppColors.primaryDark,
                      ),
                      title: const Text('Giờ nhắc'),
                      trailing: Text(
                        TimeOfDay(hour: _hour, minute: _minute).format(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primaryDark),
                      ),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ngày nhắc',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            label: Text(_weekdays[day - 1]),
                            selected: _selectedWeekdays.contains(day),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _selectedWeekdays.add(day);
                              } else {
                                _selectedWeekdays.remove(day);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('LƯU LỊCH NHẮC'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
