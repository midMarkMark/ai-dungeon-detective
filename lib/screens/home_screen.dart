import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../services/persistence_service.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import 'new_case_screen.dart';
import 'case_history_screen.dart';
import 'settings_screen.dart';
import 'investigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _menuController;
  late Animation<double> _titleAnimation;
  late Animation<double> _menuAnimation;
  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack);
    _menuAnimation = CurvedAnimation(parent: _menuController, curve: Curves.easeOutCubic);
    
    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _menuController.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForSavedCase();
  }

  void _checkForSavedCase() {
    final persistence = context.read<PersistenceService>();
    if (persistence.currentCase != null && persistence.currentCase!.status == CaseStatus.investigating) {
      if (mounted) setState(() => _showContinue = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persistence = context.watch<PersistenceService>();
    _showContinue = persistence.currentCase != null && persistence.currentCase!.status == CaseStatus.investigating;

    return Scaffold(
      body: Stack(
        children: [
          // Background atmosphere
          _buildBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Title section
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ScaleTransition(
                      scale: _titleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'CASE FILE ACTIVE',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.goldAccent,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Main title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [AppTheme.goldAccent, AppTheme.goldDark, AppTheme.goldAccent],
                            ).createShader(bounds),
                            child: Text(
                              'AI DUNGEON\nDETECTIVE',
                              textAlign: TextAlign.center,
                              style: AppTheme.noirTitle.copyWith(height: 1.1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _titleAnimation,
                            child: Text(
                              'An AI-Powered Murder Mystery',
                              style: AppTheme.noirSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Menu section
                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: _menuAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_menuAnimation),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMenuButton(
                              icon: Icons.play_circle_filled_rounded,
                              label: 'NEW CASE',
                              subtitle: 'Generate a fresh mystery',
                              onTap: () => _navigateToNewCase(),
                              isPrimary: true,
                            ),
                            const SizedBox(height: 16),
                            if (_showContinue)
                              _buildMenuButton(
                                icon: Icons.play_arrow_rounded,
                                label: 'CONTINUE INVESTIGATION',
                                subtitle: _getCaseSubtitle(persistence.currentCase!),
                                onTap: () => _continueInvestigation(persistence.currentCase!),
                                isPrimary: false,
                                highlight: true,
                              ),
                            if (_showContinue) const SizedBox(height: 16),
                            _buildMenuButton(
                              icon: Icons.history_rounded,
                              label: 'CASE HISTORY',
                              subtitle: 'Review past investigations',
                              onTap: () => _navigateToCaseHistory(),
                              isPrimary: false,
                            ),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                              icon: Icons.settings_rounded,
                              label: 'SETTINGS',
                              subtitle: 'Configure your experience',
                              onTap: () => _navigateToSettings(),
                              isPrimary: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: FadeTransition(
                    opacity: _menuAnimation,
                    child: Column(
                      children: [
                        Text(
                          'QuillBot AI  •  Offline-First  •  Noir Atmosphere',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            color: AppTheme.paperDark.withValues(alpha: 0.5),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v1.0.0  |  Built with Flutter',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            color: AppTheme.paperDark.withValues(alpha: 0.3),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
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
      child: Stack(
        children: [
          // Subtle vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  AppTheme.noirBlack.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Floating particles
          ...List.generate(15, (index) => _FloatingParticle(index: index)),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isPrimary,
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary 
                ? AppTheme.goldAccent 
                : highlight 
                  ? AppTheme.bloodRed.withValues(alpha: 0.5)
                  : AppTheme.goldAccent.withValues(alpha: 0.3),
              width: isPrimary || highlight ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                ? [
                    AppTheme.goldAccent.withValues(alpha: 0.1),
                    AppTheme.goldDark.withValues(alpha: 0.05),
                  ]
                : highlight
                  ? [
                      AppTheme.bloodRed.withValues(alpha: 0.08),
                      AppTheme.noirDarkGrey,
                    ]
                  : [
                      AppTheme.noirDarkGrey,
                      AppTheme.noirMediumGrey,
                    ],
            ),
            boxShadow: isPrimary || highlight
              ? [
                  BoxShadow(
                    color: (isPrimary ? AppTheme.goldAccent : AppTheme.bloodRed).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                    ? AppTheme.goldAccent.withValues(alpha: 0.2)
                    : highlight
                      ? AppTheme.bloodRed.withValues(alpha: 0.15)
                      : AppTheme.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? AppTheme.goldAccent : highlight ? AppTheme.bloodRed : AppTheme.goldDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? AppTheme.noirBlack : highlight ? AppTheme.bloodRed : AppTheme.paperWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary 
                          ? AppTheme.noirBlack.withValues(alpha: 0.7)
                          : AppTheme.paperDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isPrimary ? AppTheme.noirBlack : AppTheme.goldAccent.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCaseSubtitle(GameCase gameCase) {
    return '${gameCase.title}  •  ${gameCase.suspects.length} suspects  •  ${gameCase.discoveredClueIds.length}/${gameCase.clues.length} clues found';
  }

  void _navigateToNewCase() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const NewCaseScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _checkForSavedCase());
  }

  void _continueInvestigation(GameCase gameCase) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => InvestigationScreen(gameCase: gameCase),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _checkForSavedCase());
  }

  void _navigateToCaseHistory() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CaseHistoryScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _checkForSavedCase());
  }
}

class _FloatingParticle extends StatefulWidget {
  final int index;
  const _FloatingParticle({required this.index});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startX;
  late double _speed;

  @override
  void initState() {
    super.initState();
    _startX = (DateTime.now().millisecondsSinceEpoch + widget.index * 17) % 100 / 100;
    _speed = 0.5 + (widget.index % 5) * 0.3;
    _controller = AnimationController(
      duration: Duration(seconds: (20 + widget.index * 3)),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final y = 1.0 - (_animation.value + widget.index * 0.1) % 1.0;
        final x = (_startX + _animation.value * 0.1 * _speed) % 1.0;
        return Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y,
          child: Opacity(
            opacity: (0.1 + (widget.index % 3) * 0.05) * (0.5 + 0.5 * (1 - (y - 0.5).abs() * 2)),
            child: Container(
              width: 2 + widget.index % 3,
              height: 2 + widget.index % 3,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}