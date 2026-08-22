import 'package:equatable/equatable.dart';
import 'suspect.dart';
import 'clue.dart';
import 'location.dart';
import 'timeline_event.dart';
import 'conversation_message.dart';
import 'relationship.dart';

enum CaseStatus { generated, investigating, accused, solved, failed }

class GameCase extends Equatable {
  final String id;
  final String title;
  final CaseStatus status;
  final Victim victim;
  final MurderDetails murder;
  final List<Suspect> suspects;
  final List<Clue> clues;
  final List<Location> locations;
  final List<TimelineEvent> timeline;
  final List<Relationship> relationships;
  final Map<String, List<ConversationMessage>> conversations; // suspectId -> messages
  final Set<String> discoveredClueIds;
  final Set<String> visitedLocationIds;
  final Set<String> interrogatedSuspectIds;
  final String? accusationSuspectId;
  final String? accusationReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int playTimeSeconds;
  final String? solutionSummary;

  const GameCase({
    required this.id,
    required this.title,
    required this.status,
    required this.victim,
    required this.murder,
    required this.suspects,
    required this.clues,
    required this.locations,
    required this.timeline,
    required this.relationships,
    required this.conversations,
    required this.discoveredClueIds,
    required this.visitedLocationIds,
    required this.interrogatedSuspectIds,
    this.accusationSuspectId,
    this.accusationReason,
    required this.createdAt,
    this.completedAt,
    required this.playTimeSeconds,
    this.solutionSummary,
  });

  // Get the murderer suspect
  Suspect? get murderer {
    try {
      return suspects.firstWhere((s) => s.id == murder.murdererId);
    } catch (_) {
      return null;
    }
  }

  // Get suspect by ID
  Suspect? getSuspect(String id) {
    try {
      return suspects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get clue by ID
  Clue? getClue(String id) {
    try {
      return clues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get location by ID
  Location? getLocation(String id) {
    try {
      return locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get conversation history for a suspect
  List<ConversationMessage> getConversation(String suspectId) {
    return conversations[suspectId] ?? [];
  }

  // Check if a clue is discovered
  bool isClueDiscovered(String clueId) => discoveredClueIds.contains(clueId);

  // Check if a location is visited
  bool isLocationVisited(String locationId) => visitedLocationIds.contains(locationId);

  // Check if a suspect has been interrogated
  bool isSuspectInterrogated(String suspectId) => interrogatedSuspectIds.contains(suspectId);

  // Get discovered clues
  List<Clue> get discoveredClues => clues.where((c) => discoveredClueIds.contains(c.id)).toList();

  // Get undiscovered clues
  List<Clue> get undiscoveredClues => clues.where((c) => !discoveredClueIds.contains(c.id)).toList();

  // Check if case is solvable (has minimum required info)
  bool get isValid {
    return murder.murdererId.isNotEmpty &&
        suspects.any((s) => s.id == murder.murdererId) &&
        murder.time.isNotEmpty &&
        murder.location.isNotEmpty &&
        murder.motive.isNotEmpty &&
        suspects.length >= 3 &&
        clues.length >= 3;
  }

  factory GameCase.fromJson(Map<String, dynamic> json) {
    return GameCase(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      status: CaseStatus.values.byName(json['status'] ?? 'generated'),
      victim: Victim.fromJson(json['victim'] ?? {}),
      murder: MurderDetails.fromJson(json['murder'] ?? {}),
      suspects: (json['suspects'] as List? ?? []).map((e) => Suspect.fromJson(e)).toList(),
      clues: (json['clues'] as List? ?? []).map((e) => Clue.fromJson(e)).toList(),
      locations: (json['locations'] as List? ?? []).map((e) => Location.fromJson(e)).toList(),
      timeline: (json['timeline'] as List? ?? []).map((e) => TimelineEvent.fromJson(e)).toList(),
      relationships: (json['relationships'] as List? ?? []).map((e) => Relationship.fromJson(e)).toList(),
      conversations: (json['conversations'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as List).map((e) => ConversationMessage.fromJson(e)).toList()),
      ),
      discoveredClueIds: (json['discoveredClueIds'] as List? ?? []).cast<String>().toSet(),
      visitedLocationIds: (json['visitedLocationIds'] as List? ?? []).cast<String>().toSet(),
      interrogatedSuspectIds: (json['interrogatedSuspectIds'] as List? ?? []).cast<String>().toSet(),
      accusationSuspectId: json['accusationSuspectId'],
      accusationReason: json['accusationReason'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      playTimeSeconds: json['playTimeSeconds'] ?? 0,
      solutionSummary: json['solutionSummary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'victim': victim.toJson(),
      'murder': murder.toJson(),
      'suspects': suspects.map((e) => e.toJson()).toList(),
      'clues': clues.map((e) => e.toJson()).toList(),
      'locations': locations.map((e) => e.toJson()).toList(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'relationships': relationships.map((e) => e.toJson()).toList(),
      'conversations': conversations.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
      ),
      'discoveredClueIds': discoveredClueIds.toList(),
      'visitedLocationIds': visitedLocationIds.toList(),
      'interrogatedSuspectIds': interrogatedSuspectIds.toList(),
      'accusationSuspectId': accusationSuspectId,
      'accusationReason': accusationReason,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'playTimeSeconds': playTimeSeconds,
      'solutionSummary': solutionSummary,
    };
  }

  GameCase copyWith({
    String? id,
    String? title,
    CaseStatus? status,
    Victim? victim,
    MurderDetails? murder,
    List<Suspect>? suspects,
    List<Clue>? clues,
    List<Location>? locations,
    List<TimelineEvent>? timeline,
    List<Relationship>? relationships,
    Map<String, List<ConversationMessage>>? conversations,
    Set<String>? discoveredClueIds,
    Set<String>? visitedLocationIds,
    Set<String>? interrogatedSuspectIds,
    String? accusationSuspectId,
    String? accusationReason,
    DateTime? createdAt,
    DateTime? completedAt,
    int? playTimeSeconds,
    String? solutionSummary,
  }) {
    return GameCase(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      victim: victim ?? this.victim,
      murder: murder ?? this.murder,
      suspects: suspects ?? this.suspects,
      clues: clues ?? this.clues,
      locations: locations ?? this.locations,
      timeline: timeline ?? this.timeline,
      relationships: relationships ?? this.relationships,
      conversations: conversations ?? this.conversations,
      discoveredClueIds: discoveredClueIds ?? this.discoveredClueIds,
      visitedLocationIds: visitedLocationIds ?? this.visitedLocationIds,
      interrogatedSuspectIds: interrogatedSuspectIds ?? this.interrogatedSuspectIds,
      accusationSuspectId: accusationSuspectId ?? this.accusationSuspectId,
      accusationReason: accusationReason ?? this.accusationReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      solutionSummary: solutionSummary ?? this.solutionSummary,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        victim,
        murder,
        suspects,
        clues,
        locations,
        timeline,
        relationships,
        conversations,
        discoveredClueIds,
        visitedLocationIds,
        interrogatedSuspectIds,
        accusationSuspectId,
        accusationReason,
        createdAt,
        completedAt,
        playTimeSeconds,
        solutionSummary,
      ];
}

class Victim extends Equatable {
  final String id;
  final String name;
  final int age;
  final String occupation;
  final String description;
  final String background;

  const Victim({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.description,
    required this.background,
  });

  factory Victim.fromJson(Map<String, dynamic> json) {
    return Victim(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      occupation: json['occupation'] ?? '',
      description: json['description'] ?? '',
      background: json['background'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'occupation': occupation,
      'description': description,
      'background': background,
    };
  }

  @override
  List<Object?> get props => [id, name, age, occupation, description, background];
}

class MurderDetails extends Equatable {
  final String murdererId;
  final String time; // e.g., "22:15"
  final String location;
  final String weapon;
  final String motive;
  final String causeOfDeath;
  final String method; // How the murder was carried out

  const MurderDetails({
    required this.murdererId,
    required this.time,
    required this.location,
    required this.weapon,
    required this.motive,
    required this.causeOfDeath,
    required this.method,
  });

  factory MurderDetails.fromJson(Map<String, dynamic> json) {
    return MurderDetails(
      murdererId: json['murdererId'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      weapon: json['weapon'] ?? '',
      motive: json['motive'] ?? '',
      causeOfDeath: json['causeOfDeath'] ?? '',
      method: json['method'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'murdererId': murdererId,
      'time': time,
      'location': location,
      'weapon': weapon,
      'motive': motive,
      'causeOfDeath': causeOfDeath,
      'method': method,
    };
  }

  @override
  List<Object?> get props => [murdererId, time, location, weapon, motive, causeOfDeath, method];
}

class Relationship extends Equatable {
  final String fromSuspectId;
  final String toSuspectId;
  final String type; // 'friend', 'enemy', 'lover', 'rival', 'colleague', 'family', 'stranger'
  final String description;
  final bool isPublic;

  const Relationship({
    required this.fromSuspectId,
    required this.toSuspectId,
    required this.type,
    required this.description,
    this.isPublic = true,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      fromSuspectId: json['fromSuspectId'] ?? '',
      toSuspectId: json['toSuspectId'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromSuspectId': fromSuspectId,
      'toSuspectId': toSuspectId,
      'type': type,
      'description': description,
      'isPublic': isPublic,
    };
  }

  @override
  List<Object?> get props => [fromSuspectId, toSuspectId, type, description, isPublic];
}