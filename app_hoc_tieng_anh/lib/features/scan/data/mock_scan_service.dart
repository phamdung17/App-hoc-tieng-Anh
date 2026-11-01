import '../domain/scan_models.dart';

class MockScanService {
  MockScanService._();
  static final MockScanService instance = MockScanService._();

  int remainingQuota = 8;
  final List<String> savedWordIds = [];

  Future<ScanResult> analyzeObject({String? imagePath, String sampleType = 'coffee'}) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (remainingQuota > 0) {
      remainingQuota--;
    }

    switch (sampleType.toLowerCase()) {
      case 'book':
        return ScanResult(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: imagePath,
          sampleEmoji: '📖',
          remainingQuota: remainingQuota,
          detectedObjects: const [
            DetectedObject(
              id: 'obj_book',
              label: 'Notebook',
              ipa: '/ˈnəʊt.bʊk/',
              partOfSpeech: 'noun',
              meaningVi: 'Quyển vở, sổ tay ghi chép',
              exampleEn: 'I write my daily study notes in this notebook.',
              exampleVi: 'Tôi viết ghi chú học tập hàng ngày vào quyển sổ này.',
              confidence: 0.97,
              box: BoundingBox(x: 0.2, y: 0.25, width: 0.6, height: 0.5),
            ),
          ],
        );

      case 'laptop':
        return ScanResult(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: imagePath,
          sampleEmoji: '💻',
          remainingQuota: remainingQuota,
          detectedObjects: const [
            DetectedObject(
              id: 'obj_laptop',
              label: 'Laptop',
              ipa: '/ˈlæp.tɒp/',
              partOfSpeech: 'noun',
              meaningVi: 'Máy tính xách tay',
              exampleEn: 'She uses a laptop to learn English online.',
              exampleVi: 'Cô ấy dùng máy tính xách tay để học tiếng Anh trực tuyến.',
              confidence: 0.98,
              box: BoundingBox(x: 0.15, y: 0.2, width: 0.7, height: 0.55),
            ),
          ],
        );

      case 'apple':
        return ScanResult(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: imagePath,
          sampleEmoji: '🍎',
          remainingQuota: remainingQuota,
          detectedObjects: const [
            DetectedObject(
              id: 'obj_apple',
              label: 'Red Apple',
              ipa: '/red ˈæp.əl/',
              partOfSpeech: 'noun',
              meaningVi: 'Quả táo đỏ',
              exampleEn: 'An apple a day keeps the doctor away.',
              exampleVi: 'Ăn một quả táo mỗi ngày giúp bạn luôn khỏe mạnh.',
              confidence: 0.99,
              box: BoundingBox(x: 0.25, y: 0.3, width: 0.5, height: 0.4),
            ),
          ],
        );

      case 'coffee':
      default:
        return ScanResult(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: imagePath,
          sampleEmoji: '☕',
          remainingQuota: remainingQuota,
          detectedObjects: const [
            DetectedObject(
              id: 'obj_cup',
              label: 'Coffee Cup',
              ipa: '/ˈkɒf.i kʌp/',
              partOfSpeech: 'noun',
              meaningVi: 'Cốc cà phê',
              exampleEn: 'He is drinking a warm cup of coffee.',
              exampleVi: 'Anh ấy đang uống một tách cà phê ấm.',
              confidence: 0.96,
              box: BoundingBox(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
            ),
          ],
        );
    }
  }

  void saveWord(String wordId) {
    if (!savedWordIds.contains(wordId)) {
      savedWordIds.add(wordId);
    }
  }
}
