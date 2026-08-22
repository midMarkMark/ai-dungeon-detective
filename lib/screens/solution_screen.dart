import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../game/accusation_engine.dart';
import '../utils/app_theme.dart';

class SolutionScreen extends StatefulWidget {
  final GameCase gameCase;
  final SolutionReveal solution;

  const SolutionScreen({super.key, required this.gameCase, required this.solution});

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentSection = 0;

  final List<_SolutionSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _buildSections();
    _controller.forward();
  }

  void _buildSections() {
    final s = widget.solution;
    final c = widget.gameCase;
    
    _sections.clear();
    _sections.addAll([
      _SolutionSection(
        title: 'THE MURDERER REVEALED',
        icon: Icons.person_search_rounded,
        color: AppTheme.bloodRed,
        content: [
          'The killer was ${s.murderer}.',
          '',
          s.murdererConfession,
        ],
      ),
      _SolutionSection(
        title: 'COMPLETE TIMELINE',
        icon: Icons.timeline_rounded,
        color: AppTheme.goldAccent,
        content: [s.completeTimeline],
      ),
      _SolutionSection(
        title: 'KEY CLUES THAT SOLVED THE CASE',
        icon: Icons.verified_rounded,
        color: AppTheme.mutedGreen,
        content: s.keyClues.map((c) => '• $c').toList(),
      ),
      _SolutionSection(
        title: 'RED HERRINGS EXPLAINED',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.goldDark,
        content: s.redHerrings.map((r) => '• $r').toList(),
      ),
      _SolutionSection(
        title: 'SUSPECT BREAKDOWN',
        icon: Icons.people_rounded,
        color: AppTheme.goldAccent,
        content: s.suspectBreakdown.map((sb) => 
          '${sb.name} (${sb.role.toUpperCase()}): ${sb.explanation}'
        ).toList(),
      ),
      _SolutionSection(
        title: 'DETECTIVE\'S CLOSING REMARKS',
        icon: Icons.menu_book_rounded,
        color: AppTheme.goldAccent,
        content: [s.detectiveSummary],
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
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
          Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: AppTheme.noirDarkGrey,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
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
                          'CASE SOLVED: ${widget.gameCase.title}',
                          style: AppTheme.noirTitle.copyWith(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'SOLVED',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldAccent,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Section indicator
              Container(
                height: 60,
                color: AppTheme.noirDarkGrey,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final isActive = index == _currentSection;
                    return GestureDetector(
                      onTap: () => setState(() => _currentSection = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive 
                            ? section.color.withValues(alpha: 0.2)
                            : AppTheme.noirMediumGrey,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? section.color : AppTheme.noirLightGrey,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(section.icon, size: 16, color: isActive ? section.color : AppTheme.paperDark),
                            const SizedBox(width: 8),
                            Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? section.color : AppTheme.paperDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildSectionContent(_sections[_currentSection]),
                    ),
                  ),
                ),
              ),
              
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.noirDarkGrey,
                  border: Border(
                    top: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('NEW CASE'),
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('CASE HISTORY'),
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                          // Navigate to case history from home
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(_SolutionSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: section.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: section.color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: section.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: section.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...section.content.map((line) {
            if (line.isEmpty) return const SizedBox(height: 16);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                line,
                style: AppTheme.evidenceText.copyWith(
                  color: section.content.indexOf(line) == 0 && line.startsWith('The killer') 
                    ? AppTheme.paperWhite 
                    : AppTheme.paperDark,
                  height: 1.7,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SolutionSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> content;

  _SolutionSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });
}