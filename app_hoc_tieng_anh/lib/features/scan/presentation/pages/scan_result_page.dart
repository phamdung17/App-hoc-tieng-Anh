import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/scan_api_service.dart';
import '../../domain/scan_models.dart';
import '../widgets/detection_overlay.dart';

IconData _sampleIcon(String? sample) => switch (sample) {
  'book' => LucideIcons.bookOpen,
  'laptop' => LucideIcons.laptop,
  'apple' => LucideIcons.apple,
  'coffee' => LucideIcons.coffee,
  _ => LucideIcons.search,
};

class ScanResultPage extends StatefulWidget {
  final ScanResult result;

  const ScanResultPage({super.key, required this.result});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  late DetectedObject _selectedObject;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _selectedObject = widget.result.detectedObjects.isEmpty
        ? const DetectedObject(
            id: '', label: '', ipa: '', partOfSpeech: '', meaningVi: '',
            exampleEn: '', exampleVi: '', confidence: 0,
            box: BoundingBox(x: 0, y: 0, width: 0, height: 0),
          )
        : widget.result.detectedObjects.first;
    _isSaved = _selectedObject.isSaved;
  }

  Future<void> _saveWord() async {
    try {
      await ScanApiService.instance.setSaved(_selectedObject.id, !_isSaved);
      if (!mounted) return;
      setState(() => _isSaved = !_isSaved);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDark,
          content: Row(
            children: [
              const Icon(LucideIcons.circleCheck, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_isSaved
                    ? 'Đã lưu “${_selectedObject.label}” vào kho từ vựng.'
                    : 'Đã xóa “${_selectedObject.label}” khỏi kho từ vựng.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được từ. Hãy đăng nhập rồi thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result.noObjects) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Kết quả nhận diện')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.scanSearch, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text('Không tìm thấy vật thể trong ảnh. Hãy thử ảnh khác.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.pop(), child: const Text('Quét ảnh khác')),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kết quả nhận diện AI',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanned Image Card with Bounding Box Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Container(
                height: 260,
                color: const Color(0xFF1E2927),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or Sample Emoji
                    if (widget.result.imagePath != null &&
                        File(widget.result.imagePath!).existsSync())
                      Image.file(
                        File(widget.result.imagePath!),
                        fit: BoxFit.cover,
                      )
                    else
                      Center(
                        child: Icon(
                          _sampleIcon(widget.result.sampleKey),
                          size: 72,
                          color: AppColors.primaryDark,
                        ),
                      ),

                    // Detection Overlay with interactive boxes
                    DetectionOverlay(
                      objects: widget.result.detectedObjects,
                      selectedObject: _selectedObject,
                      onSelectObject: (obj) {
                        setState(() {
                          _selectedObject = obj;
                          _isSaved = obj.isSaved;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detected Word Detail Card
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Word name + IPA + Speaker
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedObject.label,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedObject.partOfSpeech,
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedObject.ipa,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pronunciation button
                      IconButton.filledTonal(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Phát âm: "${_selectedObject.label}"',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.volume2,
                          color: AppColors.primaryDark,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.divider, height: 28),

                  // Meaning
                  const Text(
                    'Định nghĩa tiếng Việt:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedObject.meaningVi,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Example Sentence
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ví dụ câu:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedObject.exampleEn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedObject.exampleVi,
                          style: const TextStyle(
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

            const SizedBox(height: 24),

            // Save to Vocabulary Button
            ElevatedButton.icon(
              onPressed: _isSaved ? null : _saveWord,
              icon: Icon(
                _isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkPlus,
              ),
              label: Text(
                _isSaved ? 'ĐÃ LƯU VÀO KHO TỪ VỰNG' : 'LƯU VÀO KHO TỪ VỰNG',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                elevation: _isSaved ? 0 : 2,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Scan another button
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.divider, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Quét vật thể khác'),
            ),
          ],
        ),
      ),
    );
  }
}
