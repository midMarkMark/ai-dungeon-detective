import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../utils/app_theme.dart';
import 'investigation_screen.dart';

class CaseIntroScreen extends StatefulWidget {
  final GameCase gameCase;

  const CaseIntroScreen({super.key, required this.gameCase});

  @override
  State<CaseIntroScreen> createState() => _CaseIntroScreenState();
}

class _CaseIntroScreenState extends State<CaseIntroScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<_IntroPage> _pages = [];

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
    
    _buildPages();
    _controller.forward();
  }

  void _buildPages() {
    final c = widget.gameCase;
    _pages.clear();
    _pages.addAll([
      _IntroPage(
        title: 'CASE FILE OPENED',
        subtitle: c.title,
        icon: Icons.folder_open_rounded,
        content: [
          'Victim: ${c.victim.name}, ${c.victim.age}',
          'Occupation: ${c.victim.occupation}',
          'Time of Death: ${c.murder.time}',
          'Location: ${c.murder.location}',
          'Cause: ${c.murder.causeOfDeath}',
          'Weapon: ${c.murder.weapon}',
        ],
      ),
      _IntroPage(
        title: 'THE VICTIM',
        subtitle: c.victim.name,
        icon: Icons.person_outline_rounded,
        content: [
          c.victim.description,
          '',
          c.victim.background,
        ],
      ),
      _IntroPage(
        title: 'THE SUSPECTS',
        subtitle: '${c.suspects.length} Persons of Interest',
        icon: Icons.group_rounded,
        content: c.suspects.map((s) => 
          '${s.name}, ${s.age} - ${s.occupation} (${s.personalityDisplayName})'
        ).toList(),
      ),
      _IntroPage(
        title: 'YOUR MISSION',
        subtitle: 'Find the Killer',
        icon: Icons.gavel_rounded,
        content: [
          'Interrogate suspects using natural language',
          'Investigate crime scenes and locations',
          'Discover clues and build your case',
          'Track contradictions in testimonies',
          'Make your accusation when ready',
          '',
          'The murderer is among them. They have motive, opportunity, and something to hide.',
        ],
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
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
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: List.generate(_pages.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(right: index < _pages.length - 1 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: index <= _currentPage 
                              ? AppTheme.goldAccent 
                              : AppTheme.noirLightGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Pages
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pages.length,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return _buildPage(page);
                        },
                      ),
                    ),
                  ),
                ),
                
                // Navigation
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('BACK'),
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                        )
                      else
                        const SizedBox(width: 120),
                      
                      const Spacer(),
                      
                      if (_currentPage < _pages.length - 1)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('NEXT'),
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('BEGIN INVESTIGATION'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          onPressed: _beginInvestigation,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_IntroPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Icon(page.icon, size: 48, color: AppTheme.goldAccent),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            page.title,
            style: AppTheme.noirTitle.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            page.subtitle,
            style: AppTheme.noirSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.paperDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: page.content.map((line) {
                if (line.isEmpty) return const SizedBox(height: 12);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    line,
                    style: AppTheme.evidenceText,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _beginInvestigation() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => InvestigationScreen(gameCase: widget.gameCase),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _IntroPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> content;

  _IntroPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
  });
}