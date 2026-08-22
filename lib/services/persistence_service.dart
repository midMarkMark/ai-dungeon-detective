import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/clue.dart';
import '../models/conversation_message.dart';
import '../models/timeline_event.dart';

class PersistenceService extends ChangeNotifier {
  static const String _currentCaseKey = 'current_case';
  static const String _caseHistoryKey = 'case_history';
  static const String _settingsKey = 'settings';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;

  GameCase? _currentCase;
  List<CaseSummary> _caseHistory = [];
  AppSettings _settings = AppSettings.defaultSettings();
  bool _onboardingComplete = false;

  bool get initialized => _initialized;
  GameCase? get currentCase => _currentCase;
  List<CaseSummary> get caseHistory => _caseHistory;
  AppSettings get settings => _settings;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadAll();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadAll() async {
    // Load current case
    final caseJson = _prefs.getString(_currentCaseKey);
    if (caseJson != null) {
      try {
        _currentCase = GameCase.fromJson(jsonDecode(caseJson));
      } catch (e) {
        debugPrint('[Persistence] Failed to load current case: $e');
      }
    }

    // Load case history
    final historyJson = _prefs.getString(_caseHistoryKey);
    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List;
        _caseHistory = list.map((e) => CaseSummary.fromJson(e)).toList();
      } catch (e) {
        debugPrint('[Persistence] Failed to load case history: $e');
      }
    }

    // Load settings
    final settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        _settings = AppSettings.fromJson(jsonDecode(settingsJson));
      } catch (e) {
        debugPrint('[Persistence] Failed to load settings: $e');
      }
    }

    // Load onboarding status
    _onboardingComplete = _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // Current Case Management
  Future<void> saveCurrentCase(GameCase gameCase) async {
    _currentCase = gameCase;
    await _prefs.setString(_currentCaseKey, jsonEncode(gameCase.toJson()));
    notifyListeners();
  }

  Future<void> clearCurrentCase() async {
    _currentCase = null;
    await _prefs.remove(_currentCaseKey);
    notifyListeners();
  }

  // Case History
  Future<void> addToHistory(CaseSummary summary) async {
    _caseHistory.insert(0, summary);
    if (_caseHistory.length > 50) {
      _caseHistory = _caseHistory.sublist(0, 50);
    }
    await _prefs.setString(_caseHistoryKey, jsonEncode(_caseHistory.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> removeFromHistory(String caseId) async {
    _caseHistory.removeWhere((c) => c.id == caseId);
    await _prefs.setString(_caseHistoryKey, jsonEncode(_caseHistory.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _caseHistory.clear();
    await _prefs.remove(_caseHistoryKey);
    notifyListeners();
  }

  // Settings
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
    await _prefs.setBool(_onboardingCompleteKey, complete);
    notifyListeners();
  }

  // Convenience methods for partial case updates
  Future<void> updateCaseField(String field, dynamic value) async {
    if (_currentCase == null) return;
    // This is a simplified approach - in practice you'd want more granular updates
    await saveCurrentCase(_currentCase!);
  }
}

class AppSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool autoSave;
  final String difficulty; // 'easy', 'normal', 'hard'
  final bool showHints;
  final double textScale;

  AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.autoSave = true,
    this.difficulty = 'normal',
    this.showHints = true,
    this.textScale = 1.0,
  });

  static AppSettings defaultSettings() => AppSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      hapticsEnabled: json['hapticsEnabled'] ?? true,
      autoSave: json['autoSave'] ?? true,
      difficulty: json['difficulty'] ?? 'normal',
      showHints: json['showHints'] ?? true,
      textScale: (json['textScale'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'autoSave': autoSave,
      'difficulty': difficulty,
      'showHints': showHints,
      'textScale': textScale,
    };
  }

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? autoSave,
    String? difficulty,
    bool? showHints,
    double? textScale,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoSave: autoSave ?? this.autoSave,
      difficulty: difficulty ?? this.difficulty,
      showHints: showHints ?? this.showHints,
      textScale: textScale ?? this.textScale,
    );
  }
}

class CaseSummary {
  final String id;
  final String title;
  final String victimName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? murdererName;
  final bool solved;
  final bool correctAccusation;
  final int suspectsCount;
  final int cluesFound;
  final int playTimeMinutes;

  CaseSummary({
    required this.id,
    required this.title,
    required this.victimName,
    required this.startedAt,
    this.completedAt,
    this.murdererName,
    this.solved = false,
    this.correctAccusation = false,
    required this.suspectsCount,
    required this.cluesFound,
    required this.playTimeMinutes,
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) {
    return CaseSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      victimName: json['victimName'] ?? '',
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      murdererName: json['murdererName'],
      solved: json['solved'] ?? false,
      correctAccusation: json['correctAccusation'] ?? false,
      suspectsCount: json['suspectsCount'] ?? 0,
      cluesFound: json['cluesFound'] ?? 0,
      playTimeMinutes: json['playTimeMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'victimName': victimName,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'murdererName': murdererName,
      'solved': solved,
      'correctAccusation': correctAccusation,
      'suspectsCount': suspectsCount,
      'cluesFound': cluesFound,
      'playTimeMinutes': playTimeMinutes,
    };
  }
}