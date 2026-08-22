import 'package:equatable/equatable.dart';

enum SuspectPersonality {
  nervous,
  arrogant,
  friendly,
  defensive,
  manipulative,
  sarcastic,
  emotional,
  calm,
  hostile,
  evasive,
  talkative,
  forgetful,
  cooperative,
}

enum AlibiTruthfulness { truthful, partial, fabricated }

class Suspect extends Equatable {
  final String id;
  final String name;
  final int age;
  final String occupation;
  final SuspectPersonality personality;
  final String personalityDescription;
  final String relationshipWithVictim;
  final String publicInfo; // What everyone knows
  final String privateInfo; // What the suspect knows but doesn't share
  final List<String> secrets; // Deep secrets
  final List<String> knowledge; // Specific facts the suspect knows
  final List<String> unknowns; // Things the suspect definitely doesn't know
  final String alibi;
  final AlibiTruthfulness alibiTruthfulness;
  final List<String> lies; // Specific lies the suspect tells
  final String motivationForLying; // Why they lie (if they do)
  final String motive; // Potential motive for murder
  final bool hasOpportunity;
  final String opportunityDetails;
  final String portraitDescription; // For AI image generation or description

  const Suspect({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.personality,
    required this.personalityDescription,
    required this.relationshipWithVictim,
    required this.publicInfo,
    required this.privateInfo,
    required this.secrets,
    required this.knowledge,
    required this.unknowns,
    required this.alibi,
    required this.alibiTruthfulness,
    required this.lies,
    required this.motivationForLying,
    required this.motive,
    required this.hasOpportunity,
    required this.opportunityDetails,
    required this.portraitDescription,
  });

  factory Suspect.fromJson(Map<String, dynamic> json) {
    return Suspect(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      occupation: json['occupation'] ?? '',
      personality: SuspectPersonality.values.byName(json['personality'] ?? 'calm'),
      personalityDescription: json['personalityDescription'] ?? '',
      relationshipWithVictim: json['relationshipWithVictim'] ?? '',
      publicInfo: json['publicInfo'] ?? '',
      privateInfo: json['privateInfo'] ?? '',
      secrets: (json['secrets'] as List? ?? []).cast<String>(),
      knowledge: (json['knowledge'] as List? ?? []).cast<String>(),
      unknowns: (json['unknowns'] as List? ?? []).cast<String>(),
      alibi: json['alibi'] ?? '',
      alibiTruthfulness: AlibiTruthfulness.values.byName(json['alibiTruthfulness'] ?? 'truthful'),
      lies: (json['lies'] as List? ?? []).cast<String>(),
      motivationForLying: json['motivationForLying'] ?? '',
      motive: json['motive'] ?? '',
      hasOpportunity: json['hasOpportunity'] ?? false,
      opportunityDetails: json['opportunityDetails'] ?? '',
      portraitDescription: json['portraitDescription'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'occupation': occupation,
      'personality': personality.name,
      'personalityDescription': personalityDescription,
      'relationshipWithVictim': relationshipWithVictim,
      'publicInfo': publicInfo,
      'privateInfo': privateInfo,
      'secrets': secrets,
      'knowledge': knowledge,
      'unknowns': unknowns,
      'alibi': alibi,
      'alibiTruthfulness': alibiTruthfulness.name,
      'lies': lies,
      'motivationForLying': motivationForLying,
      'motive': motive,
      'hasOpportunity': hasOpportunity,
      'opportunityDetails': opportunityDetails,
      'portraitDescription': portraitDescription,
    };
  }

  String get personalityDisplayName {
    switch (personality) {
      case SuspectPersonality.nervous:
        return 'Nervous';
      case SuspectPersonality.arrogant:
        return 'Arrogant';
      case SuspectPersonality.friendly:
        return 'Friendly';
      case SuspectPersonality.defensive:
        return 'Defensive';
      case SuspectPersonality.manipulative:
        return 'Manipulative';
      case SuspectPersonality.sarcastic:
        return 'Sarcastic';
      case SuspectPersonality.emotional:
        return 'Emotional';
      case SuspectPersonality.calm:
        return 'Calm';
      case SuspectPersonality.hostile:
        return 'Hostile';
      case SuspectPersonality.evasive:
        return 'Evasive';
      case SuspectPersonality.talkative:
        return 'Talkative';
      case SuspectPersonality.forgetful:
        return 'Forgetful';
      case SuspectPersonality.cooperative:
        return 'Cooperative';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        occupation,
        personality,
        personalityDescription,
        relationshipWithVictim,
        publicInfo,
        privateInfo,
        secrets,
        knowledge,
        unknowns,
        alibi,
        alibiTruthfulness,
        lies,
        motivationForLying,
        motive,
        hasOpportunity,
        opportunityDetails,
        portraitDescription,
      ];
}