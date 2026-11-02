import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import 'welcome_page.dart' show OnboardingPrimaryAction;

class OnboardingSurveyPage extends StatefulWidget {
  const OnboardingSurveyPage({super.key});

  @override
  State<OnboardingSurveyPage> createState() => _OnboardingSurveyPageState();
}

class _OnboardingSurveyPageState extends State<OnboardingSurveyPage> {
  int _step = 0;
  String _goal = 'Giao tiếp';
  String _level = 'Cơ bản';
  int _minutes = 10;

  static const _goals = [
    _SurveyOption(
      'Giao tiếp',
      'Tự tin trò chuyện mỗi ngày',
      'goal_messages.svg',
    ),
    _SurveyOption(
      'Công việc',
      'Kết nối và phát triển sự nghiệp',
      'goal_briefcase.svg',
    ),
    _SurveyOption('Du lịch', 'Khám phá thế giới dễ dàng hơn', 'goal_plane.svg'),
    _SurveyOption('Học tập', 'Vững kiến thức, mở tương lai', 'goal_study.svg'),
  ];

  static const _levels = [
    _SurveyOption('Mới bắt đầu', 'Mở khóa Chặng 1', 'level_sprout.svg'),
    _SurveyOption('Cơ bản', 'Mở khóa Chặng 1–2', 'level_leaf.svg'),
    _SurveyOption('Khá', 'Mở khóa Chặng 1–4', 'level_tree.svg'),
  ];

  static const _minutesOptions = [5, 10, 15, 20];
  static const _minutesIcons = [
    'time_coffee.svg',
    'time_flame.svg',
    'time_zap.svg',
    'time_rocket.svg',
  ];
  static const _minutesDescriptions = [
    'Khởi động nhẹ nhàng',
    'Đều đặn mỗi ngày',
    'Tăng tốc tiến bộ',
    'Bứt phá bản thân',
  ];

  void _continue() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      context.go('/auth');
    }
  }

  void _back() {
    if (_step == 0) {
      context.go('/welcome');
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 6),
          child: Column(
            children: [
              _SurveyNavigation(step: _step + 1, onBack: _back),
              const SizedBox(height: 18),
              _ProgressTrack(step: _step),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    0 => _goalStep(),
                    1 => _levelStep(),
                    _ => _durationStep(),
                  },
                ),
              ),
              if (_step == 0 || _step == 2) ...[
                const SizedBox(height: 10),
                Text(
                  _step == 0
                      ? 'Bạn có thể thay đổi lựa chọn này sau.'
                      : 'Tiếp theo: tạo tài khoản để lưu lộ trình.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OnboardingPrimaryAction(
                label: 'Tiếp tục',
                onPressed: _continue,
                icon: LucideIcons.arrowRight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalStep() {
    return _SurveyStepContent(
      key: const ValueKey(0),
      eyebrow: 'MỤC TIÊU HỌC TẬP',
      title: 'Bạn học tiếng Anh\nđể làm gì?',
      subtitle: 'Chọn mục tiêu để LingoUp đồng hành cùng bạn nhé.',
      child: Column(
        children: [
          for (final option in _goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionTile(
                option: option,
                selected: _goal == option.title,
                onTap: () => setState(() => _goal = option.title),
              ),
            ),
        ],
      ),
    );
  }

  Widget _levelStep() {
    return _SurveyStepContent(
      key: const ValueKey(1),
      eyebrow: 'ĐIỂM KHỞI ĐẦU',
      title: 'Tiếng Anh của bạn\nđang ở mức nào?',
      subtitle: 'Chọn mức gần với bạn nhất để bắt đầu ở chặng phù hợp.',
      child: Column(
        children: [
          for (final option in _levels)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionTile(
                option: option,
                selected: _level == option.title,
                onTap: () => setState(() => _level = option.title),
              ),
            ),
          const SizedBox(height: 2),
          const _LevelEncouragement(),
        ],
      ),
    );
  }

  Widget _durationStep() {
    return _SurveyStepContent(
      key: const ValueKey(2),
      eyebrow: 'THÓI QUEN MỖI NGÀY',
      title: 'Mỗi ngày, mình học\nbao lâu nhỉ?',
      subtitle: 'Một chút mỗi ngày, tiến xa hơn bạn nghĩ. Chọn nhịp học phù hợp với bạn.',
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _minutesOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 112,
            ),
            itemBuilder: (context, index) => _DurationTile(
              minutes: _minutesOptions[index],
              subtitle: _minutesDescriptions[index],
              icon: _minutesIcons[index],
              selected: _minutes == _minutesOptions[index],
              onTap: () => setState(() => _minutes = _minutesOptions[index]),
            ),
          ),
          const SizedBox(height: 18),
          _RouteSummary(goal: _goal, level: _level, minutes: _minutes),
        ],
      ),
    );
  }
}

class _SurveyNavigation extends StatelessWidget {
  const _SurveyNavigation({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.outline, width: 1.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            'Lộ trình của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$step/3',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 7,
              decoration: BoxDecoration(
                color: index <= step
                    ? AppColors.primary
                    : const Color(0xFFE7E4DC),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (index < 2) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SurveyStepContent extends StatelessWidget {
  const _SurveyStepContent({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: .7,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 27,
              height: 1.12,
              letterSpacing: -.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SurveyOption {
  const _SurveyOption(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final String icon;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _SurveyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : const Color(0xFFFFF0C8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _surveyIcon(option.icon),
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _SelectionMark(selected: selected),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.minutes,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final int minutes;
  final String subtitle;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_surveyIcon(icon), size: 22, color: AppColors.textPrimary),
              const Spacer(),
              if (selected) _SelectionMark(selected: true),
            ],
          ),
          const Spacer(),
          Text(
            '$minutes phút',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelEncouragement extends StatelessWidget {
  const _LevelEncouragement();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.lightbulb,
            size: 24,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cứ bắt đầu thoải mái nhé. Mỗi bài học là một bước tiến nhỏ!',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.goal,
    required this.level,
    required this.minutes,
  });
  final String goal;
  final String level;
  final int minutes;

  String get _units => switch (level) {
    'Mới bắt đầu' => 'Chặng 1',
    'Cơ bản' => 'Chặng 1–2',
    _ => 'Chặng 1–4',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lộ trình dành riêng cho bạn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$goal · $level · $_units',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                LucideIcons.clock3,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 7),
              Text(
                'Mục tiêu hôm nay: $minutes phút',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE7F8F2) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.outline : AppColors.divider,
          width: 1.25,
        ),
      ),
      child: selected
          ? const Icon(
              LucideIcons.check,
              size: 14,
              color: AppColors.textPrimary,
            )
          : null,
    );
  }
}

IconData _surveyIcon(String asset) => switch (asset) {
  'goal_work.svg' => LucideIcons.briefcaseBusiness,
  'goal_conversation.svg' => LucideIcons.messagesSquare,
  'goal_plane.svg' => LucideIcons.plane,
  'goal_study.svg' => LucideIcons.graduationCap,
  'level_sprout.svg' => LucideIcons.sprout,
  'level_leaf.svg' => LucideIcons.leaf,
  'level_tree.svg' => LucideIcons.treeDeciduous,
  _ => LucideIcons.clock3,
};
