import 'package:equatable/equatable.dart';

enum TimelineEventType {
  murder,
  preMurder,
  postMurder,
  alibi,
  witness,
  clueDiscovery,
  suspiciousActivity,
}

class TimelineEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String time; // e.g., "21:30"
  final String locationId;
  final List<String> participantSuspectIds;
  final TimelineEventType type;
  final bool isConfirmed; // Has the player confirmed this?
  final bool isPlayerVisible; // Should the player see this in notebook?
  final String source; // How was this discovered? 'evidence', 'testimony', 'investigation', 'deduction'
  final List<String> supportingClueIds;
  final List<String> contradictingClueIds;

  const TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.locationId,
    required this.participantSuspectIds,
    required this.type,
    this.isConfirmed = false,
    this.isPlayerVisible = false,
    required this.source,
    required this.supportingClueIds,
    required this.contradictingClueIds,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      locationId: json['locationId'] ?? '',
      participantSuspectIds: (json['participantSuspectIds'] as List? ?? []).cast<String>(),
      type: TimelineEventType.values.byName(json['type'] ?? 'preMurder'),
      isConfirmed: json['isConfirmed'] ?? false,
      isPlayerVisible: json['isPlayerVisible'] ?? false,
      source: json['source'] ?? '',
      supportingClueIds: (json['supportingClueIds'] as List? ?? []).cast<String>(),
      contradictingClueIds: (json['contradictingClueIds'] as List? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'locationId': locationId,
      'participantSuspectIds': participantSuspectIds,
      'type': type.name,
      'isConfirmed': isConfirmed,
      'isPlayerVisible': isPlayerVisible,
      'source': source,
      'supportingClueIds': supportingClueIds,
      'contradictingClueIds': contradictingClueIds,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TimelineEventType.murder:
        return '💀 Murder';
      case TimelineEventType.preMurder:
        return '⏰ Before Murder';
      case TimelineEventType.postMurder:
        return '🕐 After Murder';
      case TimelineEventType.alibi:
        return '📋 Alibi';
      case TimelineEventType.witness:
        return '👁️ Witness';
      case TimelineEventType.clueDiscovery:
        return '🔍 Clue Found';
      case TimelineEventType.suspiciousActivity:
        return '⚠️ Suspicious';
    }
  }

  TimelineEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? time,
    String? locationId,
    List<String>? participantSuspectIds,
    TimelineEventType? type,
    bool? isConfirmed,
    bool? isPlayerVisible,
    String? source,
    List<String>? supportingClueIds,
    List<String>? contradictingClueIds,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      locationId: locationId ?? this.locationId,
      participantSuspectIds: participantSuspectIds ?? this.participantSuspectIds,
      type: type ?? this.type,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isPlayerVisible: isPlayerVisible ?? this.isPlayerVisible,
      source: source ?? this.source,
      supportingClueIds: supportingClueIds ?? this.supportingClueIds,
      contradictingClueIds: contradictingClueIds ?? this.contradictingClueIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        time,
        locationId,
        participantSuspectIds,
        type,
        isConfirmed,
        isPlayerVisible,
        source,
        supportingClueIds,
        contradictingClueIds,
      ];
}