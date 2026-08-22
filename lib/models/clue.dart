import 'package:equatable/equatable.dart';

enum ClueType {
  physical,
  digital,
  testimonial,
  documentary,
  forensic,
  circumstantial,
}

enum ClueImportance { critical, major, minor, redHerring }

class Clue extends Equatable {
  final String id;
  final String name;
  final String description;
  final ClueType type;
  final ClueImportance importance;
  final String locationId; // Where it can be found
  final List<String> discoveryConditions; // What must happen to discover it
  final List<String> relatedSuspectIds;
  final List<String> relatedTimelineEventIds;
  final bool isRedHerring;
  final String redHerringExplanation; // Why it's a red herring (if applicable)
  final bool requiresAction; // Does the player need to do something specific?
  final String requiredAction; // What action reveals it

  const Clue({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.importance,
    required this.locationId,
    required this.discoveryConditions,
    required this.relatedSuspectIds,
    required this.relatedTimelineEventIds,
    this.isRedHerring = false,
    this.redHerringExplanation = '',
    this.requiresAction = true,
    this.requiredAction = '',
  });

  factory Clue.fromJson(Map<String, dynamic> json) {
    return Clue(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: ClueType.values.byName(json['type'] ?? 'physical'),
      importance: ClueImportance.values.byName(json['importance'] ?? 'minor'),
      locationId: json['locationId'] ?? '',
      discoveryConditions: (json['discoveryConditions'] as List? ?? []).cast<String>(),
      relatedSuspectIds: (json['relatedSuspectIds'] as List? ?? []).cast<String>(),
      relatedTimelineEventIds: (json['relatedTimelineEventIds'] as List? ?? []).cast<String>(),
      isRedHerring: json['isRedHerring'] ?? false,
      redHerringExplanation: json['redHerringExplanation'] ?? '',
      requiresAction: json['requiresAction'] ?? true,
      requiredAction: json['requiredAction'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'importance': importance.name,
      'locationId': locationId,
      'discoveryConditions': discoveryConditions,
      'relatedSuspectIds': relatedSuspectIds,
      'relatedTimelineEventIds': relatedTimelineEventIds,
      'isRedHerring': isRedHerring,
      'redHerringExplanation': redHerringExplanation,
      'requiresAction': requiresAction,
      'requiredAction': requiredAction,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case ClueType.physical:
        return 'Physical';
      case ClueType.digital:
        return 'Digital';
      case ClueType.testimonial:
        return 'Testimonial';
      case ClueType.documentary:
        return 'Documentary';
      case ClueType.forensic:
        return 'Forensic';
      case ClueType.circumstantial:
        return 'Circumstantial';
    }
  }

  String get importanceDisplayName {
    switch (importance) {
      case ClueImportance.critical:
        return 'Critical';
      case ClueImportance.major:
        return 'Major';
      case ClueImportance.minor:
        return 'Minor';
      case ClueImportance.redHerring:
        return 'Red Herring';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        importance,
        locationId,
        discoveryConditions,
        relatedSuspectIds,
        relatedTimelineEventIds,
        isRedHerring,
        redHerringExplanation,
        requiresAction,
        requiredAction,
      ];
}