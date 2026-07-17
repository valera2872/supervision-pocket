enum SupervisionRequestStatus {
  newRequest,
  planned,
  completed,
  continuing,
  deferred,
}

enum SupervisionMeetingStatus { planned, completed }

class SuperviseeProfile {
  const SuperviseeProfile({
    required this.id,
    required this.displayName,
    required this.professionalContext,
    required this.invitationCode,
    required this.createdAt,
    this.professionalRole = '',
    this.approach = '',
    this.experience = '',
    this.meetingCadence = '',
    this.privateNotes = '',
  });

  final String id;
  final String displayName;
  final String professionalContext;
  final String invitationCode;
  final DateTime createdAt;
  final String professionalRole;
  final String approach;
  final String experience;
  final String meetingCadence;
  final String privateNotes;

  SuperviseeProfile copyWith({
    String? displayName,
    String? professionalContext,
    String? professionalRole,
    String? approach,
    String? experience,
    String? meetingCadence,
    String? privateNotes,
  }) {
    return SuperviseeProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      professionalContext: professionalContext ?? this.professionalContext,
      invitationCode: invitationCode,
      createdAt: createdAt,
      professionalRole: professionalRole ?? this.professionalRole,
      approach: approach ?? this.approach,
      experience: experience ?? this.experience,
      meetingCadence: meetingCadence ?? this.meetingCadence,
      privateNotes: privateNotes ?? this.privateNotes,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'displayName': displayName,
        'professionalContext': professionalContext,
        'invitationCode': invitationCode,
        'createdAt': createdAt.toIso8601String(),
        'professionalRole': professionalRole,
        'approach': approach,
        'experience': experience,
        'meetingCadence': meetingCadence,
        'privateNotes': privateNotes,
      };

  factory SuperviseeProfile.fromJson(Map<String, Object?> json) {
    return SuperviseeProfile(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      professionalContext: json['professionalContext'] as String? ?? '',
      invitationCode: json['invitationCode']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      professionalRole: json['professionalRole'] as String? ?? '',
      approach: json['approach'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      meetingCadence: json['meetingCadence'] as String? ?? '',
      privateNotes: json['privateNotes'] as String? ?? '',
    );
  }
}

class SharedSupervisionRequest {
  const SharedSupervisionRequest({
    required this.id,
    required this.superviseeId,
    required this.question,
    required this.context,
    required this.receivedAt,
    this.status = SupervisionRequestStatus.newRequest,
    this.meetingId,
  });

  final String id;
  final String superviseeId;
  final String question;
  final String context;
  final DateTime receivedAt;
  final SupervisionRequestStatus status;
  final String? meetingId;

  SharedSupervisionRequest copyWith({
    SupervisionRequestStatus? status,
    String? meetingId,
    bool clearMeeting = false,
  }) {
    return SharedSupervisionRequest(
      id: id,
      superviseeId: superviseeId,
      question: question,
      context: context,
      receivedAt: receivedAt,
      status: status ?? this.status,
      meetingId: clearMeeting ? null : meetingId ?? this.meetingId,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'superviseeId': superviseeId,
        'question': question,
        'context': context,
        'receivedAt': receivedAt.toIso8601String(),
        'status': status.name,
        'meetingId': meetingId,
      };

  factory SharedSupervisionRequest.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String?;
    return SharedSupervisionRequest(
      id: json['id']! as String,
      superviseeId: json['superviseeId']! as String,
      question: json['question']! as String,
      context: json['context'] as String? ?? '',
      receivedAt: DateTime.parse(json['receivedAt']! as String),
      status: SupervisionRequestStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => SupervisionRequestStatus.newRequest,
      ),
      meetingId: json['meetingId'] as String?,
    );
  }
}

class SupervisionMeeting {
  const SupervisionMeeting({
    required this.id,
    required this.superviseeId,
    required this.scheduledAt,
    required this.createdAt,
    this.status = SupervisionMeetingStatus.planned,
    this.agendaRequestIds = const [],
    this.privatePreparationNotes = '',
    this.sharedSummary = '',
    this.nextStep = '',
    this.followUpQuestion = '',
    this.completedAt,
  });

  final String id;
  final String superviseeId;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final SupervisionMeetingStatus status;
  final List<String> agendaRequestIds;
  final String privatePreparationNotes;
  final String sharedSummary;
  final String nextStep;
  final String followUpQuestion;
  final DateTime? completedAt;

  SupervisionMeeting copyWith({
    DateTime? scheduledAt,
    SupervisionMeetingStatus? status,
    List<String>? agendaRequestIds,
    String? privatePreparationNotes,
    String? sharedSummary,
    String? nextStep,
    String? followUpQuestion,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return SupervisionMeeting(
      id: id,
      superviseeId: superviseeId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt,
      status: status ?? this.status,
      agendaRequestIds: agendaRequestIds ?? this.agendaRequestIds,
      privatePreparationNotes:
          privatePreparationNotes ?? this.privatePreparationNotes,
      sharedSummary: sharedSummary ?? this.sharedSummary,
      nextStep: nextStep ?? this.nextStep,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'superviseeId': superviseeId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'agendaRequestIds': agendaRequestIds,
        'privatePreparationNotes': privatePreparationNotes,
        'sharedSummary': sharedSummary,
        'nextStep': nextStep,
        'followUpQuestion': followUpQuestion,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory SupervisionMeeting.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String?;
    final rawAgenda = json['agendaRequestIds'] as List<Object?>? ?? const [];
    final completedAt = json['completedAt'] as String?;
    return SupervisionMeeting(
      id: json['id']! as String,
      superviseeId: json['superviseeId']! as String,
      scheduledAt: DateTime.parse(json['scheduledAt']! as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      status: SupervisionMeetingStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => SupervisionMeetingStatus.planned,
      ),
      agendaRequestIds: rawAgenda.cast<String>(),
      privatePreparationNotes:
          json['privatePreparationNotes'] as String? ?? '',
      sharedSummary: json['sharedSummary'] as String? ?? '',
      nextStep: json['nextStep'] as String? ?? '',
      followUpQuestion: json['followUpQuestion'] as String? ?? '',
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
    );
  }
}

class SupervisorWorkspace {
  const SupervisorWorkspace({
    this.supervisees = const [],
    this.requests = const [],
    this.meetings = const [],
  });

  final List<SuperviseeProfile> supervisees;
  final List<SharedSupervisionRequest> requests;
  final List<SupervisionMeeting> meetings;

  Map<String, Object?> toJson() => {
        'supervisees': supervisees.map((item) => item.toJson()).toList(),
        'requests': requests.map((item) => item.toJson()).toList(),
        'meetings': meetings.map((item) => item.toJson()).toList(),
      };

  factory SupervisorWorkspace.fromJson(Map<String, Object?> json) {
    final rawSupervisees = json['supervisees'] as List<Object?>? ?? const [];
    final rawRequests = json['requests'] as List<Object?>? ?? const [];
    final rawMeetings = json['meetings'] as List<Object?>? ?? const [];
    return SupervisorWorkspace(
      supervisees: rawSupervisees
          .map(
            (item) => SuperviseeProfile.fromJson(
              item! as Map<String, Object?>,
            ),
          )
          .toList(),
      requests: rawRequests
          .map(
            (item) => SharedSupervisionRequest.fromJson(
              item! as Map<String, Object?>,
            ),
          )
          .toList(),
      meetings: rawMeetings
          .map(
            (item) => SupervisionMeeting.fromJson(
              item! as Map<String, Object?>,
            ),
          )
          .toList(),
    );
  }
}
