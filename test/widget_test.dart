// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ai_dungeon_detective/main.dart';
import 'package:ai_dungeon_detective/services/persistence_service.dart';
import 'package:ai_dungeon_detective/services/ai_service.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PersistenceService>.value(value: PersistenceService()),
          Provider<QuillBotService>.value(value: QuillBotService()),
        ],
        child: const AIDungeonDetectiveApp(),
      ),
    );

    // Verify that the app builds without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}