import 'package:equatable/equatable.dart';

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