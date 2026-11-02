class VocabularyWord {
  const VocabularyWord({
    required this.id,
    required this.word,
    required this.ipa,
    required this.meaningVi,
    required this.partOfSpeech,
    required this.exampleEn,
    required this.exampleVi,
    required this.topic,
    required this.source,
    this.note = '',
  });

  final String id;
  final String word;
  final String ipa;
  final String meaningVi;
  final String partOfSpeech;
  final String exampleEn;
  final String exampleVi;
  final String topic;
  final String source;
  final String note;

  factory VocabularyWord.fromApi(Map<String, dynamic> json) => VocabularyWord(
    id: json['id']?.toString() ?? '',
    word: json['label'] as String? ?? '',
    ipa: json['ipa'] as String? ?? '',
    meaningVi: json['meaning_vi'] as String? ?? '',
    partOfSpeech: json['pos'] as String? ?? '',
    exampleEn: json['example_en'] as String? ?? '',
    exampleVi: json['example_vi'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    source: 'AI Scan',
  );

  VocabularyWord copyWith({String? note}) => VocabularyWord(
    id: id,
    word: word,
    ipa: ipa,
    meaningVi: meaningVi,
    partOfSpeech: partOfSpeech,
    exampleEn: exampleEn,
    exampleVi: exampleVi,
    topic: topic,
    source: source,
    note: note ?? this.note,
  );
}
