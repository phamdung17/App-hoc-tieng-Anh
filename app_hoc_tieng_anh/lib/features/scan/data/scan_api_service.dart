import 'package:dio/dio.dart';

import '../../../core/network/app_api.dart';
import '../domain/scan_models.dart';

class ScanQuota {
  const ScanQuota({required this.used, required this.limit, required this.remaining});

  final int used;
  final int limit;
  final int remaining;

  factory ScanQuota.fromJson(Map<String, dynamic> json) => ScanQuota(
    used: (json['used'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 10,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
  );
}

class ScanApiService {
  ScanApiService._();
  static final instance = ScanApiService._();
  final _api = AppApi.instance;

  Future<ScanQuota> getQuota() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/scans/quota');
    return ScanQuota.fromJson(response.data ?? const {});
  }

  Future<ScanResult> scanImage(String path) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/scans',
      data: FormData.fromMap({
        'image': await MultipartFile.fromFile(path),
      }),
    );
    final data = response.data ?? const <String, dynamic>{};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_detectedObjectFromApi)
        .toList(growable: false);
    final quota = await getQuota();
    return ScanResult(
      id: data['id'] as String? ?? '',
      imagePath: path,
      imageUrl: data['image_url'] as String?,
      detectedObjects: items,
      remainingQuota: quota.remaining,
      noObjects: data['status'] == 'no_object' || items.isEmpty,
    );
  }

  Future<void> setSaved(String itemId, bool saved) async {
    await _api.dio.patch<void>(
      '/scans/items/$itemId/saved',
      data: {'is_saved': saved},
    );
  }

  Future<List<Map<String, dynamic>>> getSavedWords() async {
    final response = await _api.dio.get<List<dynamic>>('/scans/saved-words');
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}

DetectedObject _detectedObjectFromApi(Map<String, dynamic> json) {
    final box = json['bounding_box'] as Map<String, dynamic>? ?? const {};
    return DetectedObject(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? '',
      ipa: json['ipa'] as String? ?? '',
      partOfSpeech: json['pos'] as String? ?? '',
      meaningVi: json['meaning_vi'] as String? ?? '',
      exampleEn: json['example_en'] as String? ?? '',
      exampleVi: json['example_vi'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      box: BoundingBox(
        x: (box['x'] as num?)?.toDouble() ?? 0,
        y: (box['y'] as num?)?.toDouble() ?? 0,
        width: (box['w'] as num?)?.toDouble() ?? 0,
        height: (box['h'] as num?)?.toDouble() ?? 0,
      ),
      isSaved: json['is_saved'] as bool? ?? false,
      wordId: json['word_id']?.toString(),
    );
}
