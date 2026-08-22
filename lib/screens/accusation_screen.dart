import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../game/accusation_engine.dart';
import '../services/persistence_service.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import 'solution_screen.dart';

class AccusationScreen extends StatefulWidget {
  final GameCase gameCase;

  const AccusationScreen({super.key, required this.gameCase});

  @override
  State<AccusationScreen> createState() => _AccusationScreenState();
}

class _AccusationScreenState extends State<AccusationScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String? _selectedSuspectId;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  AccusationOutcome? _outcome;

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
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.noirBlack,
                  AppTheme.noirDarkGrey,
                  AppTheme.noirBlack,
                ],
              ),
            ),
          ),
          
          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // App Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: AppTheme.noirDarkGrey,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.goldAccent),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'MAKE ACCUSATION',
                              style: AppTheme.noirTitle.copyWith(fontSize: 18, color: AppTheme.bloodRed),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  
                  // Warning banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bloodRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.bloodRed, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Once you make an accusation, the case will be closed. You cannot continue investigating. Are you certain?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperWhite),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Suspect selection
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHO IS THE MURDERER?',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.goldAccent),
                          ),
                          const SizedBox(height: 12),
                          ...widget.gameCase.suspects.map((suspect) => _buildSuspectOption(suspect)),
                          
                          const SizedBox(height: 24),
                          
                          // Reasoning input
                          Text(
                            'YOUR REASONING',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.goldAccent),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedSuspectId != null 
                                  ? AppTheme.goldAccent 
                                  : AppTheme.noirLightGrey,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _reasonController,
                              enabled: _selectedSuspectId != null && !_isSubmitting,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperWhite),
                              maxLines: 6,
                              minLines: 4,
                              decoration: InputDecoration(
                                hintText: _selectedSuspectId == null
                                  ? 'Select a suspect first...'
                                  : 'Explain your reasoning. What evidence points to this suspect? What is their motive? How did they do it?',
                                hintStyle: TextStyle(color: AppTheme.paperDark.withValues(alpha: 0.5)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                filled: true,
                                fillColor: AppTheme.noirMediumGrey,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.noirBlack),
                                    ),
                                  )
                                : const Icon(Icons.gavel_rounded, size: 28),
                              label: Text(
                                _isSubmitting ? 'PROCESSING...' : 'SUBMIT ACCUSATION',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedSuspectId != null && !_isSubmitting
                                  ? AppTheme.bloodRed
                                  : AppTheme.noirLightGrey,
                                foregroundColor: AppTheme.noirBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _selectedSuspectId != null && !_isSubmitting && _reasonController.text.trim().isNotEmpty
                                ? _submitAccusation
                                : null,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Outcome overlay
          if (_outcome != null) _buildOutcomeOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuspectOption(Suspect suspect) {
    final isSelected = _selectedSuspectId == suspect.id;
    final isInterrogated = widget.gameCase.isSuspectInterrogated(suspect.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.bloodRed : AppTheme.noirLightGrey,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? AppTheme.bloodRed.withValues(alpha: 0.1) : AppTheme.noirMediumGrey.withValues(alpha: 0.5),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedSuspectId = suspect.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.bloodRed : AppTheme.noirLightGrey,
                    width: 2,
                  ),
                  color: isSelected ? AppTheme.bloodRed : Colors.transparent,
                ),
                child: isSelected
                  ? Icon(Icons.check_rounded, size: 16, color: AppTheme.noirBlack)
                  : null,
              ),
              const SizedBox(width: 16),
              
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
                child: Text(
                  suspect.name[0],
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suspect.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.bloodRed : AppTheme.paperWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${suspect.age}  •  ${suspect.occupation}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                        ),
                        if (isInterrogated) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.mutedGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Interrogated',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: AppTheme.mutedGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatChip('Motive', suspect.motive.isEmpty ? 'None' : 'Yes', AppTheme.goldAccent),
                  const SizedBox(height: 4),
                  _buildStatChip('Opportunity', suspect.hasOpportunity ? 'Yes' : 'No', suspect.hasOpportunity ? AppTheme.mutedGreen : AppTheme.paperDark),
                  const SizedBox(height: 4),
                  _buildStatChip('Alibi', suspect.alibiTruthfulness.name, _getAlibiColor(suspect.alibiTruthfulness)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getAlibiColor(AlibiTruthfulness truthfulness) {
    switch (truthfulness) {
      case AlibiTruthfulness.truthful:
        return AppTheme.mutedGreen;
      case AlibiTruthfulness.partial:
        return AppTheme.goldAccent;
      case AlibiTruthfulness.fabricated:
        return AppTheme.bloodRed;
    }
  }

  Future<void> _submitAccusation() async {
    setState(() => _isSubmitting = true);
    
    final aiService = context.read<QuillBotService>();
    final persistence = context.read<PersistenceService>();
    final engine = AccusationEngine(aiService, persistence);
    
    final outcome = await engine.submitAccusation(
      gameCase: widget.gameCase,
      suspectId: _selectedSuspectId!,
      reasoning: _reasonController.text.trim(),
    );
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _outcome = outcome;
      });
    }
  }

  Widget _buildOutcomeOverlay() {
    final outcome = _outcome!;
    final isCorrect = outcome.correct;
    
    return Container(
      color: AppTheme.noirBlack.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.noirDarkGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed).withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed),
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 64,
                      color: isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    isCorrect ? 'CASE SOLVED' : 'ACCUSATION INCORRECT',
                    style: AppTheme.noirTitle.copyWith(
                      fontSize: 24,
                      color: isCorrect ? AppTheme.goldAccent : AppTheme.bloodRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.paperDecoration,
                    child: Text(
                      outcome.message,
                      style: AppTheme.evidenceText,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Additional info for incorrect
                  if (!isCorrect && outcome.keyEvidence.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Key Evidence You Missed:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent),
                    ),
                    const SizedBox(height: 8),
                    ...outcome.keyEvidence.map((e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $e', style: AppTheme.evidenceText.copyWith(fontSize: 12)),
                    )),
                  ],
                  
                  if (!isCorrect && outcome.missedClues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Clues to Re-examine:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent),
                    ),
                    const SizedBox(height: 8),
                    ...outcome.missedClues.map((c) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $c', style: AppTheme.evidenceText.copyWith(fontSize: 12, color: AppTheme.bloodRed)),
                    )),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  if (isCorrect && outcome.solution != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('VIEW FULL SOLUTION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.noirBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => SolutionScreen(
                              gameCase: outcome.updatedCase!,
                              solution: outcome.solution!,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    )
                  else if (!isCorrect)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('TRY AGAIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.noirBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _outcome = null;
                          _selectedSuspectId = null;
                          _reasonController.clear();
                        });
                      },
                    ),
                  
                  const SizedBox(height: 12),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'RETURN TO MENU',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}