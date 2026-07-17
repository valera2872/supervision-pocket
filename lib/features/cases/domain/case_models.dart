class CaseFile {
  const CaseFile({
    required this.id,
    required this.alias,
    required this.ageRange,
    required this.context,
    required this.createdAt,
    required this.updatedAt,
    this.entries = const [],
    this.draft,
    this.archived = false,
  });

  final String id;
  final String alias;
  final String ageRange;
  final String context;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReflectionEntry> entries;
  final ReflectionDraft? draft;
  final bool archived;

  CaseFile copyWith({
    String? alias,
    String? ageRange,
    String? context,
    DateTime? updatedAt,
    List<ReflectionEntry>? entries,
    ReflectionDraft? draft,
    bool clearDraft = false,
    bool? archived,
  }) {
    return CaseFile(
      id: id,
      alias: alias ?? this.alias,
      ageRange: ageRange ?? this.ageRange,
      context: context ?? this.context,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
      draft: clearDraft ? null : draft ?? this.draft,
      archived: archived ?? this.archived,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'alias': alias,
        'ageRange': ageRange,
        'context': context,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'draft': draft?.toJson(),
        'archived': archived,
      };

  factory CaseFile.fromJson(Map<String, Object?> json) {
    final rawEntries = json['entries'] as List<Object?>? ?? const [];
    final rawDraft = json['draft'];
    return CaseFile(
      id: json['id']! as String,
      alias: json['alias']! as String,
      ageRange: json['ageRange']! as String,
      context: json['context'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      entries: rawEntries
          .map((item) => ReflectionEntry.fromJson(item! as Map<String, Object?>))
          .toList(),
      draft: rawDraft == null
          ? null
          : ReflectionDraft.fromJson(rawDraft as Map<String, Object?>),
      archived: json['archived'] as bool? ?? false,
    );
  }
}

class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.createdAt,
    required this.observedFact,
    required this.interpretation,
    required this.feeling,
    required this.impulse,
    required this.actionTaken,
    required this.stuckPoint,
    required this.supervisionQuestion,
  });

  final String id;
  final DateTime createdAt;
  final String observedFact;
  final String interpretation;
  final String feeling;
  final String impulse;
  final String actionTaken;
  final String stuckPoint;
  final String supervisionQuestion;

  Map<String, Object?> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'observedFact': observedFact,
        'interpretation': interpretation,
        'feeling': feeling,
        'impulse': impulse,
        'actionTaken': actionTaken,
        'stuckPoint': stuckPoint,
        'supervisionQuestion': supervisionQuestion,
      };

  factory ReflectionEntry.fromJson(Map<String, Object?> json) {
    return ReflectionEntry(
      id: json['id']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      observedFact: json['observedFact'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
      feeling: json['feeling'] as String? ?? '',
      impulse: json['impulse'] as String? ?? '',
      actionTaken: json['actionTaken'] as String? ?? '',
      stuckPoint: json['stuckPoint'] as String? ?? '',
      supervisionQuestion: json['supervisionQuestion'] as String? ?? '',
    );
  }
}

class ReflectionDraft {
  const ReflectionDraft({
    required this.updatedAt,
    this.observedFact = '',
    this.interpretation = '',
    this.feeling = '',
    this.impulse = '',
    this.actionTaken = '',
    this.stuckPoint = '',
    this.supervisionQuestion = '',
  });

  final DateTime updatedAt;
  final String observedFact;
  final String interpretation;
  final String feeling;
  final String impulse;
  final String actionTaken;
  final String stuckPoint;
  final String supervisionQuestion;

  bool get isEmpty => [
        observedFact,
        interpretation,
        feeling,
        impulse,
        actionTaken,
        stuckPoint,
        supervisionQuestion,
      ].every((value) => value.trim().isEmpty);

  ReflectionEntry toEntry(String id) => ReflectionEntry(
        id: id,
        createdAt: DateTime.now(),
        observedFact: observedFact.trim(),
        interpretation: interpretation.trim(),
        feeling: feeling.trim(),
        impulse: impulse.trim(),
        actionTaken: actionTaken.trim(),
        stuckPoint: stuckPoint.trim(),
        supervisionQuestion: supervisionQuestion.trim(),
      );

  Map<String, Object?> toJson() => {
        'updatedAt': updatedAt.toIso8601String(),
        'observedFact': observedFact,
        'interpretation': interpretation,
        'feeling': feeling,
        'impulse': impulse,
        'actionTaken': actionTaken,
        'stuckPoint': stuckPoint,
        'supervisionQuestion': supervisionQuestion,
      };

  factory ReflectionDraft.fromJson(Map<String, Object?> json) {
    return ReflectionDraft(
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      observedFact: json['observedFact'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
      feeling: json['feeling'] as String? ?? '',
      impulse: json['impulse'] as String? ?? '',
      actionTaken: json['actionTaken'] as String? ?? '',
      stuckPoint: json['stuckPoint'] as String? ?? '',
      supervisionQuestion: json['supervisionQuestion'] as String? ?? '',
    );
  }
}
