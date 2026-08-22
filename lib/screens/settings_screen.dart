import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/persistence_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    return Consumer<PersistenceService>(
      builder: (context, persistence, _) {
        final settings = persistence.settings;

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
                            bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
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
                                  'SETTINGS',
                                  style: AppTheme.noirTitle.copyWith(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),

                      // Settings List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildSectionHeader('GAMEPLAY'),
                            _buildTile(
                              icon: Icons.volume_up_rounded,
                              title: 'Sound Effects',
                              subtitle: 'Enable sound effects during gameplay',
                              trailing: Switch(
                                value: settings.soundEnabled,
                                activeColor: AppTheme.goldAccent,
                                onChanged: (v) => _updateSettings(persistence, settings.copyWith(soundEnabled: v)),
                              ),
                            ),
                            _buildTile(
                              icon: Icons.vibration_rounded,
                              title: 'Haptic Feedback',
                              subtitle: 'Vibrate on interactions',
                              trailing: Switch(
                                value: settings.hapticsEnabled,
                                activeColor: AppTheme.goldAccent,
                                onChanged: (v) => _updateSettings(persistence, settings.copyWith(hapticsEnabled: v)),
                              ),
                            ),
                            _buildTile(
                              icon: Icons.save_rounded,
                              title: 'Auto Save',
                              subtitle: 'Automatically save investigation progress',
                              trailing: Switch(
                                value: settings.autoSave,
                                activeColor: AppTheme.goldAccent,
                                onChanged: (v) => _updateSettings(persistence, settings.copyWith(autoSave: v)),
                              ),
                            ),
                            _buildTile(
                              icon: Icons.lightbulb_rounded,
                              title: 'Show Hints',
                              subtitle: 'Display helpful suggestions during investigation',
                              trailing: Switch(
                                value: settings.showHints,
                                activeColor: AppTheme.goldAccent,
                                onChanged: (v) => _updateSettings(persistence, settings.copyWith(showHints: v)),
                              ),
                            ),
                            _buildTile(
                              icon: Icons.text_fields_rounded,
                              title: 'Difficulty',
                              subtitle: 'Adjust case complexity and clue availability',
                              trailing: DropdownButton<String>(
                                value: settings.difficulty,
                                dropdownColor: AppTheme.noirDarkGrey,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperWhite),
                                underline: const SizedBox(),
                                items: ['easy', 'normal', 'hard'].map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.toUpperCase()),
                                )).toList(),
                                onChanged: (v) => _updateSettings(persistence, settings.copyWith(difficulty: v!)),
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader('DISPLAY'),
                            _buildTile(
                              icon: Icons.format_size_rounded,
                              title: 'Text Scale',
                              subtitle: 'Adjust text size for readability',
                              trailing: SizedBox(
                                width: 120,
                                child: Slider(
                                  value: settings.textScale,
                                  min: 0.8,
                                  max: 1.5,
                                  divisions: 7,
                                  label: '${(settings.textScale * 100).round()}%',
                                  activeColor: AppTheme.goldAccent,
                                  inactiveColor: AppTheme.noirLightGrey,
                                  onChanged: (v) => _updateSettings(persistence, settings.copyWith(textScale: v)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader('DATA'),
                            _buildTile(
                              icon: Icons.delete_forever_rounded,
                              title: 'Clear Case History',
                              subtitle: 'Permanently delete all past cases',
                              trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.paperDark),
                              onTap: () => _showClearHistoryDialog(persistence),
                              textColor: AppTheme.bloodRed,
                            ),
                            _buildTile(
                              icon: Icons.refresh_rounded,
                              title: 'Reset Onboarding',
                              subtitle: 'Show the tutorial again on next launch',
                              trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.paperDark),
                              onTap: () => persistence.setOnboardingComplete(false),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader('ABOUT'),
                            _buildTile(
                              icon: Icons.info_rounded,
                              title: 'Version',
                              subtitle: '1.0.0',
                              trailing: const SizedBox.shrink(),
                            ),
                            _buildTile(
                              icon: Icons.code_rounded,
                              title: 'Built With',
                              subtitle: 'Flutter 3.x  •  QuillBot AI',
                              trailing: const SizedBox.shrink(),
                            ),
                            _buildTile(
                              icon: Icons.privacy_tip_rounded,
                              title: 'Privacy',
                              subtitle: 'No personal data collected. All data stored locally.',
                              trailing: const SizedBox.shrink(),
                            ),
                            _buildTile(
                              icon: Icons.bug_report_rounded,
                              title: 'Report Issue',
                              subtitle: 'Open GitHub repository',
                              trailing: Icon(Icons.open_in_new_rounded, color: AppTheme.goldAccent, size: 20),
                              onTap: () => _launchGitHub(),
                            ),

                            const SizedBox(height: 40),

                            // Credits
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.noirMediumGrey.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'AI DUNGEON DETECTIVE',
                                    style: AppTheme.noirTitle.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'An AI-powered murder mystery investigation game.\nEvery case is uniquely generated. Every suspect has secrets.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Powered by QuillBot AI\nBuilt with Flutter & Dart',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 10,
                                      color: AppTheme.goldAccent.withValues(alpha: 0.7),
                                      letterSpacing: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.goldAccent,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (textColor ?? AppTheme.goldAccent).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: textColor ?? AppTheme.goldAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor ?? AppTheme.paperWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _updateSettings(PersistenceService persistence, AppSettings newSettings) {
    persistence.updateSettings(newSettings);
  }

  void _showClearHistoryDialog(PersistenceService persistence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.noirDarkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.bloodRed),
            const SizedBox(width: 12),
            const Text('Clear Case History'),
          ],
        ),
        content: const Text('This will permanently delete all past cases. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              persistence.clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bloodRed),
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }

  void _launchGitHub() {
    // In a real app, you'd use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('GitHub: github.com/yourusername/ai-dungeon-detective'),
        backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}