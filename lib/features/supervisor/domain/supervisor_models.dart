enum SupervisionRequestStatus { newRequest, planned, completed }

class SuperviseeProfile {
  const SuperviseeProfile({
    required this.id,
    required this.displayName,
    required this.professionalContext,
    required this.invitationCode,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String professionalContext;
  final String invitationCode;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'displayName': displayName,
        'professionalContext': professionalContext,
        'invitationCode': invitationCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SuperviseeProfile.fromJson(Map<String, Object?> json) {
    return SuperviseeProfile(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      professionalContext: json['professionalContext'] as String? ?? '',
      invitationCode: json['invitationCode']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
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
  });

  final String id;
  final String superviseeId;
  final String question;
  final String context;
  final DateTime receivedAt;
  final SupervisionRequestStatus status;

  SharedSupervisionRequest copyWith({
    SupervisionRequestStatus? status,
  }) {
    return SharedSupervisionRequest(
      id: id,
      superviseeId: superviseeId,
      question: question,
      context: context,
      receivedAt: receivedAt,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'superviseeId': superviseeId,
        'question': question,
        'context': context,
        'receivedAt': receivedAt.toIso8601String(),
        'status': status.name,
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
    );
  }
}

class SupervisorWorkspace {
  const SupervisorWorkspace({
    this.supervisees = const [],
    this.requests = const [],
  });

  final List<SuperviseeProfile> supervisees;
  final List<SharedSupervisionRequest> requests;

  Map<String, Object?> toJson() => {
        'supervisees': supervisees.map((item) => item.toJson()).toList(),
        'requests': requests.map((item) => item.toJson()).toList(),
      };

  factory SupervisorWorkspace.fromJson(Map<String, Object?> json) {
    final rawSupervisees = json['supervisees'] as List<Object?>? ?? const [];
    final rawRequests = json['requests'] as List<Object?>? ?? const [];
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
    );
  }
}
