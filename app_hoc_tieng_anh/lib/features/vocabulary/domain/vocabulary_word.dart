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
