import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/conversation_message.dart';
import '../services/persistence_service.dart';
import 'package:flutter/foundation.dart';

class ContradictionEngine {
  final PersistenceService _persistence;

  ContradictionEngine(this._persistence);

  /// Analyze conversation for contradictions
  List<Contradiction> detectContradictions(GameCase gameCase, String suspectId) {
    final conversation = gameCase.getConversation(suspectId);
    final contradictions = <Contradiction>[];
    
    // Group messages by topic/keywords
    final topicMessages = _groupByTopic(conversation);
    
    for (final entry in topicMessages.entries) {
      final messages = entry.value;
      if (messages.length < 2) continue;
      
      final topicContradictions = _findContradictionsInTopic(entry.key, messages, gameCase, suspectId);
      contradictions.addAll(topicContradictions);
    }
    
    return contradictions;
  }

  Map<String, List<ConversationMessage>> _groupByTopic(List<ConversationMessage> messages) {
    final groups = <String, List<ConversationMessage>>{};
    final topicKeywords = {
      'alibi': ['alibi', 'where were you', 'where was you', 'location at', 'at the time', 'doing at'],
      'time': ['time', 'when', 'clock', 'hour', 'minute', 'o\'clock', 'pm', 'am'],
      'relationship': ['know', 'knew', 'relationship', 'friend', 'enemy', 'met', 'talk'],
      'weapon': ['weapon', 'knife', 'gun', 'poison', 'letter opener', 'blunt'],
      'motive': ['motive', 'reason', 'why', 'money', 'jealous', 'revenge', 'inherit'],
      'evidence': ['evidence', 'clue', 'proof', 'fingerprint', 'dna', 'camera', 'footage'],
    };

    for (final message in messages) {
      if (message.role != MessageRole.suspect) continue;
      final content = message.content.toLowerCase();
      var matched = false;
      
      for (final entry in topicKeywords.entries) {
        for (final keyword in entry.value) {
          if (content.contains(keyword)) {
            groups.putIfAbsent(entry.key, () => []).add(message);
            matched = true;
            break;
          }
        }
        if (matched) break;
      }
      
      if (!matched) {
        groups.putIfAbsent('general', () => []).add(message);
      }
    }
    
    return groups;
  }

  List<Contradiction> _findContradictionsInTopic(
    String topic,
    List<ConversationMessage> messages,
    GameCase gameCase,
    String suspectId,
  ) {
    final contradictions = <Contradiction>[];
    final suspect = gameCase.getSuspect(suspectId);
    if (suspect == null) return contradictions;

    // Simple contradiction detection: look for mutually exclusive statements
    // This is a basic implementation - in production you'd want more sophisticated NLP
    for (int i = 0; i < messages.length; i++) {
      for (int j = i + 1; j < messages.length; j++) {
        final msg1 = messages[i];
        final msg2 = messages[j];
        
        final contradiction = _checkContradiction(msg1, msg2, topic, suspect);
        if (contradiction != null) {
          contradictions.add(contradiction);
        }
      }
    }
    
    return contradictions;
  }

  Contradiction? _checkContradiction(
    ConversationMessage msg1,
    ConversationMessage msg2,
    String topic,
    Suspect suspect,
  ) {
    final content1 = msg1.content.toLowerCase();
    final content2 = msg2.content.toLowerCase();
    
    // Check for time contradictions
    if (topic == 'alibi' || topic == 'time') {
      final time1 = _extractTime(content1);
      final time2 = _extractTime(content2);
      final location1 = _extractLocation(content1);
      final location2 = _extractLocation(content2);
      
      if (time1 != null && time2 != null && time1 != time2) {
        return Contradiction(
          id: 'contradiction_${DateTime.now().millisecondsSinceEpoch}',
          suspectId: suspect.id,
          suspectName: suspect.name,
          topic: 'Timeline/Alibi',
          statement1: msg1.content,
          statement2: msg2.content,
          timestamp1: msg1.timestamp,
          timestamp2: msg2.timestamp,
          description: 'Suspect gave different times for their whereabouts',
          severity: ContradictionSeverity.high,
        );
      }
      
      if (location1 != null && location2 != null && location1 != location2) {
        return Contradiction(
          id: 'contradiction_${DateTime.now().millisecondsSinceEpoch}',
          suspectId: suspect.id,
          suspectName: suspect.name,
          topic: 'Location',
          statement1: msg1.content,
          statement2: msg2.content,
          timestamp1: msg1.timestamp,
          timestamp2: msg2.timestamp,
          description: 'Suspect claimed to be in different locations',
          severity: ContradictionSeverity.high,
        );
      }
    }
    
    // Check for relationship contradictions
    if (topic == 'relationship') {
      final knows1 = _checkKnows(content1);
      final knows2 = _checkKnows(content2);
      if (knows1 != null && knows2 != null && knows1 != knows2) {
        return Contradiction(
          id: 'contradiction_${DateTime.now().millisecondsSinceEpoch}',
          suspectId: suspect.id,
          suspectName: suspect.name,
          topic: 'Relationship Knowledge',
          statement1: msg1.content,
          statement2: msg2.content,
          timestamp1: msg1.timestamp,
          timestamp2: msg2.timestamp,
          description: 'Suspect contradicted themselves about knowing someone',
          severity: ContradictionSeverity.medium,
        );
      }
    }
    
    return null;
  }

  String? _extractTime(String content) {
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?');
    final match = timeRegex.firstMatch(content);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return null;
  }

  String? _extractLocation(String content) {
    final locations = ['home', 'office', 'restaurant', 'bar', 'park', 'warehouse', 'hotel', 'house', 'apartment', 'crime scene', 'victim\'s'];
    for (final loc in locations) {
      if (content.contains(loc)) return loc;
    }
    return null;
  }

  bool? _checkKnows(String content) {
    if (content.contains('don\'t know') || content.contains('do not know') || content.contains('never met') || content.contains('never heard')) {
      return false;
    }
    if (content.contains('know') || content.contains('met') || content.contains('friend') || content.contains('acquaintance')) {
      return true;
    }
    return null;
  }

  /// Get all contradictions across all suspects
  Map<String, List<Contradiction>> getAllContradictions(GameCase gameCase) {
    final allContradictions = <String, List<Contradiction>>{};
    
    for (final suspect in gameCase.suspects) {
      final contradictions = detectContradictions(gameCase, suspect.id);
      if (contradictions.isNotEmpty) {
        allContradictions[suspect.id] = contradictions;
      }
    }
    
    return allContradictions;
  }
}

class Contradiction {
  final String id;
  final String suspectId;
  final String suspectName;
  final String topic;
  final String statement1;
  final String statement2;
  final DateTime timestamp1;
  final DateTime timestamp2;
  final String description;
  final ContradictionSeverity severity;

  Contradiction({
    required this.id,
    required this.suspectId,
    required this.suspectName,
    required this.topic,
    required this.statement1,
    required this.statement2,
    required this.timestamp1,
    required this.timestamp2,
    required this.description,
    required this.severity,
  });
}

enum ContradictionSeverity { low, medium, high, critical }