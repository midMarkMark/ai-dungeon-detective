import '../models/case_model.dart';
import '../models/suspect.dart';
import '../services/ai_service.dart';
import '../services/ai_prompt_builder.dart';
import '../services/persistence_service.dart';
import 'package:flutter/foundation.dart';

class AccusationEngine {
  final QuillBotService _aiService;
  final PersistenceService _persistence;

  AccusationEngine(this._aiService, this._persistence);

  /// Evaluate a player's accusation
  Future<AccusationResult?> evaluateAccusation({
    required GameCase gameCase,
    required String suspectId,
    required String reasoning,
  }) async {
    final prompt = AiPromptBuilder.buildAccusationEvaluationPrompt(
      gameCase: gameCase,
      accusedSuspectId: suspectId,
      playerReasoning: reasoning,
    );

    try {
      final json = await _aiService.sendPromptJson(prompt);
      if (json == null) {
        return AccusationResult(
          correct: false,
          verdict: 'Unable to evaluate accusation. Please try again.',
          keyEvidence: [],
          missedClues: [],
        );
      }

      final correct = json['correct'] ?? false;
      final verdict = json['verdict'] ?? 'No verdict provided.';
      final keyEvidence = (json['keyEvidence'] as List? ?? []).cast<String>();
      final missedClues = (json['missedClues'] as List? ?? []).cast<String>();
      final actualSolution = json['actualSolution'] as String?;

      return AccusationResult(
        correct: correct,
        verdict: verdict,
        keyEvidence: keyEvidence,
        missedClues: missedClues,
        actualSolution: actualSolution,
      );
    } catch (e) {
      debugPrint('[AccusationEngine] Error evaluating accusation: $e');
      return AccusationResult(
        correct: false,
        verdict: 'An error occurred while evaluating your accusation.',
        keyEvidence: [],
        missedClues: [],
      );
    }
  }

  /// Submit final accusation and handle result
  Future<AccusationOutcome> submitAccusation({
    required GameCase gameCase,
    required String suspectId,
    required String reasoning,
  }) async {
    final result = await evaluateAccusation(
      gameCase: gameCase,
      suspectId: suspectId,
      reasoning: reasoning,
    );

    if (result == null) {
      return AccusationOutcome(
        success: false,
        message: 'Failed to process accusation.',
      );
    }

    if (result.correct) {
      // Generate full solution reveal
      final solution = await _generateSolutionReveal(gameCase);
      
      final updatedCase = gameCase.copyWith(
        status: CaseStatus.solved,
        accusationSuspectId: suspectId,
        accusationReason: reasoning,
        completedAt: DateTime.now(),
        solutionSummary: solution?.detectiveSummary,
      );
      
      await _persistence.saveCurrentCase(updatedCase);
      await _persistence.addToHistory(CaseSummary(
        id: gameCase.id,
        title: gameCase.title,
        victimName: gameCase.victim.name,
        startedAt: gameCase.createdAt,
        completedAt: DateTime.now(),
        murdererName: gameCase.murderer?.name,
        solved: true,
        correctAccusation: true,
        suspectsCount: gameCase.suspects.length,
        cluesFound: gameCase.discoveredClueIds.length,
        playTimeMinutes: (gameCase.playTimeSeconds / 60).round(),
      ));

      return AccusationOutcome(
        success: true,
        correct: true,
        message: result.verdict,
        solution: solution,
        updatedCase: updatedCase,
      );
    } else {
      final updatedCase = gameCase.copyWith(
        status: CaseStatus.failed,
        accusationSuspectId: suspectId,
        accusationReason: reasoning,
      );
      
      await _persistence.saveCurrentCase(updatedCase);
      await _persistence.addToHistory(CaseSummary(
        id: gameCase.id,
        title: gameCase.title,
        victimName: gameCase.victim.name,
        startedAt: gameCase.createdAt,
        completedAt: DateTime.now(),
        murdererName: null, // Don't reveal
        solved: true,
        correctAccusation: false,
        suspectsCount: gameCase.suspects.length,
        cluesFound: gameCase.discoveredClueIds.length,
        playTimeMinutes: (gameCase.playTimeSeconds / 60).round(),
      ));

      return AccusationOutcome(
        success: true,
        correct: false,
        message: result.verdict,
        keyEvidence: result.keyEvidence,
        missedClues: result.missedClues,
        updatedCase: updatedCase,
      );
    }
  }

  Future<SolutionReveal?> _generateSolutionReveal(GameCase gameCase) async {
    final prompt = AiPromptBuilder.buildSolutionRevealPrompt(gameCase: gameCase);
    
    try {
      final json = await _aiService.sendPromptJson(prompt);
      if (json == null) return null;

      return SolutionReveal(
        title: json['title'] ?? 'Case Solved',
        murderer: json['murderer'] ?? 'Unknown',
        murdererConfession: json['murdererConfession'] ?? '',
        completeTimeline: json['completeTimeline'] ?? '',
        keyClues: (json['keyClues'] as List? ?? []).cast<String>(),
        redHerrings: (json['redHerrings'] as List? ?? []).cast<String>(),
        suspectBreakdown: (json['suspectBreakdown'] as List? ?? [])
            .map((e) => SuspectBreakdown.fromJson(e))
            .toList(),
        detectiveSummary: json['detectiveSummary'] ?? '',
      );
    } catch (e) {
      debugPrint('[AccusationEngine] Error generating solution: $e');
      return null;
    }
  }
}

class AccusationResult {
  final bool correct;
  final String verdict;
  final List<String> keyEvidence;
  final List<String> missedClues;
  final String? actualSolution;

  AccusationResult({
    required this.correct,
    required this.verdict,
    required this.keyEvidence,
    required this.missedClues,
    this.actualSolution,
  });
}

class AccusationOutcome {
  final bool success;
  final bool correct;
  final String message;
  final SolutionReveal? solution;
  final List<String> keyEvidence;
  final List<String> missedClues;
  final GameCase? updatedCase;

  AccusationOutcome({
    required this.success,
    this.correct = false,
    required this.message,
    this.solution,
    this.keyEvidence = const [],
    this.missedClues = const [],
    this.updatedCase,
  });
}

class SolutionReveal {
  final String title;
  final String murderer;
  final String murdererConfession;
  final String completeTimeline;
  final List<String> keyClues;
  final List<String> redHerrings;
  final List<SuspectBreakdown> suspectBreakdown;
  final String detectiveSummary;

  SolutionReveal({
    required this.title,
    required this.murderer,
    required this.murdererConfession,
    required this.completeTimeline,
    required this.keyClues,
    required this.redHerrings,
    required this.suspectBreakdown,
    required this.detectiveSummary,
  });
}

class SuspectBreakdown {
  final String name;
  final String role; // 'murderer', 'innocent', 'liar'
  final String explanation;

  SuspectBreakdown({
    required this.name,
    required this.role,
    required this.explanation,
  });

  factory SuspectBreakdown.fromJson(Map<String, dynamic> json) {
    return SuspectBreakdown(
      name: json['name'] ?? '',
      role: json['role'] ?? 'innocent',
      explanation: json['explanation'] ?? '',
    );
  }
}