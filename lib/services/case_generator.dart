import 'dart:convert';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/clue.dart';
import '../models/location.dart';
import '../models/timeline_event.dart';
import '../models/conversation_message.dart';
import '../services/ai_service.dart';
import '../services/ai_prompt_builder.dart';
import '../services/persistence_service.dart';
import 'package:flutter/foundation.dart';

class CaseGenerator {
  final QuillBotService _aiService;
  final PersistenceService _persistence;
  static const int _maxRetries = 3;

  CaseGenerator(this._aiService, this._persistence);

  /// Generate a new murder case using AI
  Future<GameCase?> generateCase({String? theme, int suspectCount = 5, int clueCount = 8}) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('[CaseGenerator] Generating case (attempt $attempt/$_maxRetries)...');
        
        final prompt = AiPromptBuilder.buildCaseGenerationPrompt(
          theme: theme,
          suspectCount: suspectCount,
          clueCount: clueCount,
        );

        final json = await _aiService.sendPromptJson(prompt);
        
        if (json == null) {
          debugPrint('[CaseGenerator] Failed to parse JSON response');
          continue;
        }

        final gameCase = _parseCaseFromJson(json);
        
        if (gameCase == null) {
          debugPrint('[CaseGenerator] Failed to create GameCase from JSON');
          continue;
        }

        // Validate the case
        final validation = CaseValidator.validate(gameCase);
        if (!validation.isValid) {
          debugPrint('[CaseGenerator] Case validation failed: ${validation.errors.join(', ')}');
          continue;
        }

        debugPrint('[CaseGenerator] Case generated successfully: ${gameCase.title}');
        return gameCase;
      } catch (e) {
        debugPrint('[CaseGenerator] Error generating case (attempt $attempt): $e');
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  GameCase? _parseCaseFromJson(Map<String, dynamic> json) {
    try {
      final victim = Victim.fromJson(json['victim'] ?? {});
      final murder = MurderDetails.fromJson(json['murder'] ?? {});
      
      final suspects = (json['suspects'] as List? ?? [])
          .map((e) => Suspect.fromJson(e))
          .toList();
      
      final clues = (json['clues'] as List? ?? [])
          .map((e) => Clue.fromJson(e))
          .toList();
      
      final locations = (json['locations'] as List? ?? [])
          .map((e) => Location.fromJson(e))
          .toList();
      
      final timeline = (json['timeline'] as List? ?? [])
          .map((e) => TimelineEvent.fromJson(e))
          .toList();
      
      final relationships = (json['relationships'] as List? ?? [])
          .map((e) => Relationship.fromJson(e))
          .toList();

      // Initialize empty conversations for each suspect
      final conversations = <String, List<ConversationMessage>>{};
      for (final suspect in suspects) {
        conversations[suspect.id] = [];
      }

      return GameCase(
        id: json['id'] ?? 'case_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] ?? 'Untitled Case',
        status: CaseStatus.generated,
        victim: victim,
        murder: murder,
        suspects: suspects,
        clues: clues,
        locations: locations,
        timeline: timeline,
        relationships: relationships,
        conversations: conversations,
        discoveredClueIds: {},
        visitedLocationIds: {},
        interrogatedSuspectIds: {},
        createdAt: DateTime.now(),
        playTimeSeconds: 0,
      );
    } catch (e) {
      debugPrint('[CaseGenerator] Parse error: $e');
      return null;
    }
  }

  /// Save case and initialize investigation
  Future<void> startInvestigation(GameCase gameCase) async {
    final updatedCase = gameCase.copyWith(
      status: CaseStatus.investigating,
    );
    await _persistence.saveCurrentCase(updatedCase);
  }
}

class CaseValidator {
  static ValidationResult validate(GameCase gameCase) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check murderer exists and is a suspect
    if (gameCase.murder.murdererId.isEmpty) {
      errors.add('No murderer assigned');
    } else if (!gameCase.suspects.any((s) => s.id == gameCase.murder.murdererId)) {
      errors.add('Murderer ID does not match any suspect');
    }

    // Check murder details
    if (gameCase.murder.time.isEmpty) {
      errors.add('Murder time is missing');
    }
    if (gameCase.murder.location.isEmpty) {
      errors.add('Murder location is missing');
    }
    if (gameCase.murder.motive.isEmpty) {
      errors.add('Murder motive is missing');
    }
    if (gameCase.murder.weapon.isEmpty) {
      errors.add('Murder weapon is missing');
    }
    if (gameCase.murder.causeOfDeath.isEmpty) {
      errors.add('Cause of death is missing');
    }
    if (gameCase.murder.method.isEmpty) {
      errors.add('Murder method is missing');
    }

    // Check suspect count
    if (gameCase.suspects.length < 3) {
      errors.add('Need at least 3 suspects (got ${gameCase.suspects.length})');
    }

    // Check each suspect has required fields
    for (int i = 0; i < gameCase.suspects.length; i++) {
      final s = gameCase.suspects[i];
      if (s.name.isEmpty) errors.add('Suspect $i missing name');
      if (s.id.isEmpty) errors.add('Suspect $i missing ID');
      if (s.personalityDescription.isEmpty) warnings.add('Suspect ${s.name} missing personality description');
      if (s.alibi.isEmpty) warnings.add('Suspect ${s.name} missing alibi');
      if (s.motive.isEmpty) warnings.add('Suspect ${s.name} missing motive');
    }

    // Check clue count
    if (gameCase.clues.length < 3) {
      errors.add('Need at least 3 clues (got ${gameCase.clues.length})');
    }

    // Check for at least one red herring
    final hasRedHerring = gameCase.clues.any((c) => c.isRedHerring);
    if (!hasRedHerring) {
      warnings.add('No red herring clues found - consider adding one for ambiguity');
    }

    // Check timeline coherence
    if (gameCase.timeline.isEmpty) {
      warnings.add('No timeline events defined');
    } else {
      final murderEvents = gameCase.timeline.where((t) => t.type == TimelineEventType.murder).toList();
      if (murderEvents.isEmpty) {
        warnings.add('No murder event in timeline');
      } else if (murderEvents.length > 1) {
        warnings.add('Multiple murder events in timeline');
      }
    }

    // Check locations
    if (gameCase.locations.isEmpty) {
      errors.add('No locations defined');
    } else {
      final crimeScenes = gameCase.locations.where((l) => l.isCrimeScene).toList();
      if (crimeScenes.isEmpty) {
        warnings.add('No crime scene location marked');
      }
    }

    // Check for critical clues
    final criticalClues = gameCase.clues.where((c) => c.importance == ClueImportance.critical).toList();
    if (criticalClues.isEmpty) {
      warnings.add('No critical clues - case may be too difficult');
    }

    // Check murderer has motive and opportunity
    final murderer = gameCase.murderer;
    if (murderer != null) {
      if (murderer.motive.isEmpty) {
        errors.add('Murderer has no motive');
      }
      if (!murderer.hasOpportunity) {
        warnings.add('Murderer has no opportunity - case may be unsolvable');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}