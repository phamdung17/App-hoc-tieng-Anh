// Domain models for AI Scan and object detection

class BoundingBox {
  final double x; // Normalized 0..1
  final double y; // Normalized 0..1
  final double width; // Normalized 0..1
  final double height; // Normalized 0..1

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class DetectedObject {
  final String id;
  final String label;
  final String ipa;
  final String partOfSpeech;
  final String meaningVi;
  final String exampleEn;
  final String exampleVi;
  final double confidence;
  final BoundingBox box;

  const DetectedObject({
    required this.id,
    required this.label,
    required this.ipa,
    required this.partOfSpeech,
    required this.meaningVi,
    required this.exampleEn,
    required this.exampleVi,
    required this.confidence,
    required this.box,
  });
}

class ScanResult {
  final String id;
  final String? imagePath;
  final String? sampleEmoji;
  final List<DetectedObject> detectedObjects;
  final int remainingQuota;

  const ScanResult({
    required this.id,
    this.imagePath,
    this.sampleEmoji,
    required this.detectedObjects,
    this.remainingQuota = 8,
  });
}
