import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ai_service.dart';
import 'services/persistence_service.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistence
  final persistence = PersistenceService();
  await persistence.init();

  // Initialize AI service
  final aiService = QuillBotService();
  await aiService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: persistence),
        Provider.value(value: aiService),
      ],
      child: const AIDungeonDetectiveApp(),
    ),
  );
}

class AIDungeonDetectiveApp extends StatelessWidget {
  const AIDungeonDetectiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dungeon Detective',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}