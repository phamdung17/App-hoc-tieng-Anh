import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/mock_scan_service.dart';
import '../widgets/scan_quota_badge.dart';

class ScanCameraPage extends StatefulWidget {
  const ScanCameraPage({super.key});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage> with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  String _analyzingStatus = 'Đang kết nối AI...';
  String _selectedSample = 'coffee';

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _processScan({String? imagePath, required String sampleType}) async {
    setState(() {
      _isAnalyzing = true;
      _analyzingStatus = 'Gemini AI đang phân tích hình ảnh...';
    });

    try {
      final result = await MockScanService.instance.analyzeObject(
        imagePath: imagePath,
        sampleType: sampleType,
      );

      if (!mounted) return;
      context.push('/scan-result', extra: result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phân tích ảnh lúc này. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        await _processScan(imagePath: picked.path, sampleType: _selectedSample);
      }
    } catch (e) {
      // In case emulator or permissions issues occur, fallback to sample object smoothly
      _processScan(sampleType: _selectedSample);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingQuota = MockScanService.instance.remainingQuota;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Viewfinder Mock / Live Preview area
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F1E),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Target Sample Icon / Preview
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getSampleEmoji(_selectedSample),
                            style: const TextStyle(fontSize: 84),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hướng khung quét vào vật thể',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Laser Scan Line
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(0, (_scanAnimation.value * 2) - 1),
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.1),
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Corner brackets
                      const _CornerBrackets(),
                    ],
                  ),
                ),
              ),
            ),

            // Top Header: Back button, Quota, Flash
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  ),
                  ScanQuotaBadge(remaining: remainingQuota),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.flash_off_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // Quick Samples Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Column(
                children: [
                  const Text(
                    'Hoặc chọn mẫu vật thể để thử ngay:',
                    style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SampleChip(
                          emoji: '☕',
                          label: 'Cà phê',
                          isSelected: _selectedSample == 'coffee',
                          onTap: () => setState(() => _selectedSample = 'coffee'),
                        ),
                        _SampleChip(
                          emoji: '📖',
                          label: 'Sổ tay',
                          isSelected: _selectedSample == 'book',
                          onTap: () => setState(() => _selectedSample = 'book'),
                        ),
                        _SampleChip(
                          emoji: '💻',
                          label: 'Laptop',
                          isSelected: _selectedSample == 'laptop',
                          onTap: () => setState(() => _selectedSample = 'laptop'),
                        ),
                        _SampleChip(
                          emoji: '🍎',
                          label: 'Quả táo',
                          isSelected: _selectedSample == 'apple',
                          onTap: () => setState(() => _selectedSample = 'apple'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Shutter Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Pick
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 30),
                    tooltip: 'Chọn ảnh từ thư viện',
                  ),

                  // Big Shutter Button
                  GestureDetector(
                    onTap: () => _processScan(sampleType: _selectedSample),
                    child: Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  // Camera flip / sample trigger
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 30),
                    tooltip: 'Chụp ảnh thật',
                  ),
                ],
              ),
            ),

            // Analyzing Loading Overlay
            if (_isAnalyzing)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 20),
                      Text(
                        _analyzingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSampleEmoji(String sample) {
    switch (sample) {
      case 'book':
        return '📖';
      case 'laptop':
        return '💻';
      case 'apple':
        return '🍎';
      case 'coffee':
      default:
        return '☕';
    }
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const thickness = 3.5;
    const color = AppColors.primary;

    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Top Right
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom Left
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom Right
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SampleChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white12,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
