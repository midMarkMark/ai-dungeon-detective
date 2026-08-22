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

class InvestigationEngine {
  final QuillBotService _aiService;
  final PersistenceService _persistence;
  GameCase? _currentCase;
  String? _currentSuspectId;
  String? _currentLocationId;

  InvestigationEngine(this._aiService, this._persistence);

  GameCase? get currentCase => _currentCase;
  String? get currentSuspectId => _currentSuspectId;
  String? get currentLocationId => _currentLocationId;

  void setCurrentCase(GameCase gameCase) {
    _currentCase = gameCase;
  }

  void clearCurrentCase() {
    _currentCase = null;
    _currentSuspectId = null;
    _currentLocationId = null;
  }

  /// Start interrogating a suspect
  Future<void> startInterrogation(String suspectId) async {
    if (_currentCase == null) return;
    final suspect = _currentCase!.getSuspect(suspectId);
    if (suspect == null) return;
    
    _currentSuspectId = suspectId;
    _currentLocationId = null;
    
    // Mark suspect as interrogated
    final updatedCase = _currentCase!.copyWith(
      interrogatedSuspectIds: {..._currentCase!.interrogatedSuspectIds, suspectId},
    );
    _currentCase = updatedCase;
    await _persistence.saveCurrentCase(updatedCase);
  }

  /// Send a question to the current suspect
  Future<String?> askSuspect(String question) async {
    if (_currentCase == null || _currentSuspectId == null) return null;
    
    final suspect = _currentCase!.getSuspect(_currentSuspectId!);
    if (suspect == null) return null;

    final conversation = _currentCase!.getConversation(_currentSuspectId!);
    final knownClues = _currentCase!.discoveredClues;
    final knownTimeline = _currentCase!.timeline.where((t) => t.isPlayerVisible).toList();

    final prompt = AiPromptBuilder.buildInterrogationPrompt(
      gameCase: _currentCase!,
      suspect: suspect,
      playerQuestion: question,
      conversationHistory: conversation,
      knownClues: knownClues,
      knownTimeline: knownTimeline,
    );

    try {
      final response = await _aiService.sendPrompt(prompt);
      return response?.trim();
    } catch (e) {
      debugPrint('[InvestigationEngine] Error asking suspect: $e');
      return 'The connection seems to have failed. Try again.';
    }
  }

  /// Add a message to the conversation history
  Future<void> addConversationMessage(
    String suspectId,
    MessageRole role,
    String content, {
    bool isImportant = false,
    String? relatedClueId,
    String? contradictionNote,
  }) async {
    if (_currentCase == null) return;

    final message = ConversationMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: role,
      content: content,
      suspectId: suspectId,
      timestamp: DateTime.now(),
      isImportant: isImportant,
      relatedClueId: relatedClueId,
      contradictionNote: contradictionNote,
    );

    final conversations = Map<String, List<ConversationMessage>>.from(_currentCase!.conversations);
    conversations[suspectId] = [...(conversations[suspectId] ?? []), message];

    final updatedCase = _currentCase!.copyWith(conversations: conversations);
    _currentCase = updatedCase;
    await _persistence.saveCurrentCase(updatedCase);
  }

  /// Investigate a location
  Future<void> visitLocation(String locationId) async {
    if (_currentCase == null) return;
    final location = _currentCase!.getLocation(locationId);
    if (location == null) return;

    _currentLocationId = locationId;
    _currentSuspectId = null;

    final updatedCase = _currentCase!.copyWith(
      visitedLocationIds: {..._currentCase!.visitedLocationIds, locationId},
    );
    _currentCase = updatedCase;
    await _persistence.saveCurrentCase(updatedCase);
  }

  /// Perform an investigation action at the current location
  Future<String?> investigateLocation(String action) async {
    if (_currentCase == null || _currentLocationId == null) return null;

    final location = _currentCase!.getLocation(_currentLocationId!);
    if (location == null) return null;

    final availableClues = location.clueIds
        .map((id) => _currentCase!.getClue(id))
        .where((c) => c != null && !_currentCase!.discoveredClueIds.contains(c!.id))
        .cast<Clue>()
        .toList();

    final presentSuspects = location.suspectIds
        .map((id) => _currentCase!.getSuspect(id))
        .where((s) => s != null)
        .cast<Suspect>()
        .toList();

    final prompt = AiPromptBuilder.buildLocationInvestigationPrompt(
      gameCase: _currentCase!,
      location: location,
      playerAction: action,
      availableClues: availableClues,
      presentSuspects: presentSuspects,
    );

    try {
      final response = await _aiService.sendPrompt(prompt);
      return response?.trim();
    } catch (e) {
      debugPrint('[InvestigationEngine] Error investigating location: $e');
      return 'Something went wrong with your investigation. Try again.';
    }
  }

  /// Discover a clue (called when player successfully finds one)
  Future<void> discoverClue(String clueId) async {
    if (_currentCase == null) return;
    if (_currentCase!.discoveredClueIds.contains(clueId)) return;

    final clue = _currentCase!.getClue(clueId);
    if (clue == null) return;

    // Update timeline events related to this clue to be player-visible
    final updatedTimeline = _currentCase!.timeline.map((event) {
      if (event.supportingClueIds.contains(clueId)) {
        return event.copyWith(isPlayerVisible: true, isConfirmed: true, source: 'evidence');
      }
      return event;
    }).toList();

    final updatedCase = _currentCase!.copyWith(
      discoveredClueIds: {..._currentCase!.discoveredClueIds, clueId},
      timeline: updatedTimeline,
    );
    _currentCase = updatedCase;
    await _persistence.saveCurrentCase(updatedCase);
  }

  /// Get clues available at current location
  List<Clue> getAvailableCluesAtCurrentLocation() {
    if (_currentCase == null || _currentLocationId == null) return [];
    
    final location = _currentCase!.getLocation(_currentLocationId!);
    if (location == null) return [];

    return location.clueIds
        .map((id) => _currentCase!.getClue(id))
        .where((c) => c != null && !_currentCase!.discoveredClueIds.contains(c!.id))
        .cast<Clue>()
        .toList();
  }

  /// Get all discovered clues
  List<Clue> getDiscoveredClues() {
    if (_currentCase == null) return [];
    return _currentCase!.discoveredClues;
  }

  /// Get all suspects
  List<Suspect> getAllSuspects() {
    if (_currentCase == null) return [];
    return _currentCase!.suspects;
  }

  /// Get all locations
  List<Location> getAllLocations() {
    if (_currentCase == null) return [];
    return _currentCase!.locations;
  }

  /// Get conversation history for a suspect
  List<ConversationMessage> getConversation(String suspectId) {
    if (_currentCase == null) return [];
    return _currentCase!.getConversation(suspectId);
  }

  /// Get visible timeline events
  List<TimelineEvent> getVisibleTimeline() {
    if (_currentCase == null) return [];
    return _currentCase!.timeline.where((t) => t.isPlayerVisible).toList();
  }

  /// Update play time
  Future<void> updatePlayTime(int seconds) async {
    if (_currentCase == null) return;
    final updatedCase = _currentCase!.copyWith(
      playTimeSeconds: _currentCase!.playTimeSeconds + seconds,
    );
    _currentCase = updatedCase;
    await _persistence.saveCurrentCase(updatedCase);
  }
}