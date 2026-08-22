import 'package:equatable/equatable.dart';

enum MessageRole { detective, suspect, system }

class ConversationMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final String suspectId; // For suspect messages
  final DateTime timestamp;
  final bool isImportant; // Marked as important by player or detected contradiction
  final String? relatedClueId; // If this message revealed a clue
  final String? contradictionNote; // If this message contradicts something

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    this.suspectId = '',
    required this.timestamp,
    this.isImportant = false,
    this.relatedClueId,
    this.contradictionNote,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] ?? '',
      role: MessageRole.values.byName(json['role'] ?? 'detective'),
      content: json['content'] ?? '',
      suspectId: json['suspectId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isImportant: json['isImportant'] ?? false,
      relatedClueId: json['relatedClueId'],
      contradictionNote: json['contradictionNote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'suspectId': suspectId,
      'timestamp': timestamp.toIso8601String(),
      'isImportant': isImportant,
      'relatedClueId': relatedClueId,
      'contradictionNote': contradictionNote,
    };
  }

  ConversationMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    String? suspectId,
    DateTime? timestamp,
    bool? isImportant,
    String? relatedClueId,
    String? contradictionNote,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      suspectId: suspectId ?? this.suspectId,
      timestamp: timestamp ?? this.timestamp,
      isImportant: isImportant ?? this.isImportant,
      relatedClueId: relatedClueId ?? this.relatedClueId,
      contradictionNote: contradictionNote ?? this.contradictionNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        suspectId,
        timestamp,
        isImportant,
        relatedClueId,
        contradictionNote,
      ];
}