import 'package:equatable/equatable.dart';

class Location extends Equatable {
  final String id;
  final String name;
  final String description;
  final String detailedDescription; // More detailed description for investigation
  final List<String> connectedLocationIds; // For navigation
  final List<String> clueIds; // Clues that can be found here
  final List<String> suspectIds; // Suspects that might be here
  final bool isCrimeScene;
  final bool isLocked;
  final String unlockCondition; // What's needed to access
  final String atmosphere; // Noir atmosphere description
  final String backgroundDetails; // Background details for the location
  final Map<String, String> interactiveElements; // elementId -> description

  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.detailedDescription,
    required this.connectedLocationIds,
    required this.clueIds,
    required this.suspectIds,
    this.isCrimeScene = false,
    this.isLocked = false,
    this.unlockCondition = '',
    required this.atmosphere,
    required this.backgroundDetails,
    required this.interactiveElements,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      detailedDescription: json['detailedDescription'] ?? '',
      connectedLocationIds: (json['connectedLocationIds'] as List? ?? []).cast<String>(),
      clueIds: (json['clueIds'] as List? ?? []).cast<String>(),
      suspectIds: (json['suspectIds'] as List? ?? []).cast<String>(),
      isCrimeScene: json['isCrimeScene'] ?? false,
      isLocked: json['isLocked'] ?? false,
      unlockCondition: json['unlockCondition'] ?? '',
      atmosphere: json['atmosphere'] ?? '',
      backgroundDetails: json['backgroundDetails'] ?? '',
      interactiveElements: (json['interactiveElements'] as Map<String, dynamic>? ?? {}).cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'detailedDescription': detailedDescription,
      'connectedLocationIds': connectedLocationIds,
      'clueIds': clueIds,
      'suspectIds': suspectIds,
      'isCrimeScene': isCrimeScene,
      'isLocked': isLocked,
      'unlockCondition': unlockCondition,
      'atmosphere': atmosphere,
      'backgroundDetails': backgroundDetails,
      'interactiveElements': interactiveElements,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        detailedDescription,
        connectedLocationIds,
        clueIds,
        suspectIds,
        isCrimeScene,
        isLocked,
        unlockCondition,
        atmosphere,
        backgroundDetails,
        interactiveElements,
      ];
}