import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../services/case_generator.dart';
import '../services/persistence_service.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import 'investigation_screen.dart';
import 'case_intro_screen.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _suspectCount = 5;
  int _clueCount = 8;
  String _selectedTheme = 'Classic Noir';
  bool _isGenerating = false;
  String _generationStatus = '';
  double _generationProgress = 0.0;

  final List<String> _themes = [
    'Classic Noir',
    'Victorian Mansion',
    '1920s Speakeasy',
    'Modern Corporate',
    'Academic Campus',
    'Hollywood Studio',
    'Remote Island Resort',
    'Cyberpunk Metropolis',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW CASE'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Case Parameters',
                  style: AppTheme.noirTitle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your murder mystery investigation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
                ),
                const SizedBox(height: 32),

                // Theme Selection
                _buildSectionTitle('Mystery Theme'),
                const SizedBox(height: 12),
                _buildThemeSelector(),
                const SizedBox(height: 24),

                // Suspect Count
                _buildSectionTitle('Number of Suspects'),
                const SizedBox(height: 12),
                _buildSlider(
                  value: _suspectCount.toDouble(),
                  min: 3,
                  max: 8,
                  divisions: 5,
                  label: '$_suspectCount suspects',
                  onChanged: (v) => setState(() => _suspectCount = v.round()),
                ),
                const SizedBox(height: 24),

                // Clue Count
                _buildSectionTitle('Number of Clues'),
                const SizedBox(height: 12),
                _buildSlider(
                  value: _clueCount.toDouble(),
                  min: 5,
                  max: 15,
                  divisions: 10,
                  label: '$_clueCount clues',
                  onChanged: (v) => setState(() => _clueCount = v.round()),
                ),
                const SizedBox(height: 32),

                // Generate Button
                if (!_isGenerating) _buildGenerateButton(),

                // Generation Progress
                if (_isGenerating) _buildGenerationProgress(),

                const SizedBox(height: 24),

                // Info card
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.goldAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.goldAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTheme,
          isExpanded: true,
          dropdownColor: AppTheme.noirDarkGrey,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.goldAccent),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.paperWhite),
          selectedItemBuilder: (context) => _themes.map((theme) => 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.category_rounded, color: AppTheme.goldAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(theme, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.paperWhite)),
                ],
              ),
            )
          ).toList(),
          items: _themes.map((theme) => DropdownMenuItem(
            value: theme,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.category_rounded, color: AppTheme.goldAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(theme, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.paperWhite)),
                ],
              ),
            ),
          )).toList(),
          onChanged: (value) => setState(() => _selectedTheme = value!),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.noirMediumGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'SpaceMono',
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.goldAccent,
              inactiveTrackColor: AppTheme.noirLightGrey,
              thumbColor: AppTheme.goldAccent,
              overlayColor: AppTheme.goldAccent.withValues(alpha: 0.2),
              valueIndicatorColor: AppTheme.goldAccent,
              valueIndicatorTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.noirBlack),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.auto_awesome_rounded, size: 24),
        label: const Text('GENERATE CASE'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.goldAccent,
          foregroundColor: AppTheme.noirBlack,
        ),
        onPressed: _generateCase,
      ),
    );
  }

  Widget _buildGenerationProgress() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.noirMediumGrey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _generationStatus,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.paperWhite),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _generationProgress,
                  minHeight: 6,
                  backgroundColor: AppTheme.noirLightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_generationProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'SpaceMono',
                  color: AppTheme.goldAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isGenerating = false),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.noirMediumGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'What to Expect',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.goldAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'AI generates a unique murder case with logical solution',
            'Each suspect has distinct personality, secrets, and motives',
            'Interrogate naturally - type questions in your own words',
            'Investigate locations to discover physical evidence',
            'Track contradictions in suspect testimonies',
            'Make your accusation when you have enough evidence',
          ].map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.goldAccent)),
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _generateCase() async {
    setState(() {
      _isGenerating = true;
      _generationStatus = 'Initializing AI...';
      _generationProgress = 0.1;
    });

    try {
      final aiService = context.read<QuillBotService>();
      final persistence = context.read<PersistenceService>();
      final generator = CaseGenerator(aiService, persistence);

      setState(() {
        _generationStatus = 'Generating murder case...';
        _generationProgress = 0.3;
      });

      final gameCase = await generator.generateCase(
        theme: _selectedTheme,
        suspectCount: _suspectCount,
        clueCount: _clueCount,
      );

      if (gameCase == null) {
        throw Exception('Failed to generate valid case after retries');
      }

      setState(() {
        _generationStatus = 'Validating case logic...';
        _generationProgress = 0.8;
      });

      await generator.startInvestigation(gameCase);

      setState(() {
        _generationStatus = 'Case ready!';
        _generationProgress = 1.0;
      });

      if (!mounted) return;

      // Navigate to case intro
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CaseIntroScreen(gameCase: gameCase),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationStatus = '';
        _generationProgress = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate case: $e'),
          backgroundColor: AppTheme.bloodRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}