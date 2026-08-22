import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../utils/app_theme.dart';

class SuspectsScreen extends StatelessWidget {
  final GameCase gameCase;

  const SuspectsScreen({super.key, required this.gameCase});

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
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.noirDarkGrey,
                foregroundColor: AppTheme.goldAccent,
                title: Text('SUSPECT PROFILES', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.goldAccent)),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppTheme.goldAccent.withValues(alpha: 0.2),
                  ),
                ),
              ),
              
              // Suspects list
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final suspect = gameCase.suspects[index];
                      final isInterrogated = gameCase.isSuspectInterrogated(suspect.id);
                      return _SuspectProfileCard(
                        suspect: suspect,
                        isInterrogated: isInterrogated,
                        showSecrets: gameCase.status == CaseStatus.solved || gameCase.status == CaseStatus.failed,
                      );
                    },
                    childCount: gameCase.suspects.length,
                  ),
                ),
              ),
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuspectProfileCard extends StatelessWidget {
  final Suspect suspect;
  final bool isInterrogated;
  final bool showSecrets;

  const _SuspectProfileCard({
    required this.suspect,
    required this.isInterrogated,
    required this.showSecrets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldAccent.withValues(alpha: 0.1),
                  AppTheme.goldDark.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.goldAccent.withValues(alpha: 0.3), AppTheme.goldDark.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      suspect.name[0],
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.goldAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suspect.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.paperWhite,
                              ),
                            ),
                          ),
                          if (isInterrogated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.mutedGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.mutedGreen.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 14, color: AppTheme.mutedGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'INTERROGATED',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.mutedGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${suspect.age} years old  •  ${suspect.occupation}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          suspect.personalityDisplayName,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, 'Relationship to Victim', suspect.relationshipWithVictim),
                _buildDetailRow(context, 'Personality', '${suspect.personalityDisplayName} - ${suspect.personalityDescription}'),
                _buildDetailRow(context, 'Public Information', suspect.publicInfo),
                
                if (showSecrets) ...[
                  const Divider(color: AppTheme.noirLightGrey, height: 28),
                  Text(
                    'CLASSIFIED - CASE RESOLVED',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.bloodRed,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Private Information', suspect.privateInfo),
                  _buildDetailRow(context, 'Alibi', '${suspect.alibi} (${suspect.alibiTruthfulness.name})'),
                  _buildDetailRow(context, 'Motive', suspect.motive.isEmpty ? 'None apparent' : suspect.motive),
                  _buildDetailRow(context, 'Opportunity', suspect.hasOpportunity ? 'Yes - ${suspect.opportunityDetails}' : 'No clear opportunity'),
                  
                  if (suspect.secrets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Secrets:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                    ...suspect.secrets.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• $s', style: AppTheme.evidenceText.copyWith(fontSize: 12)),
                    )),
                  ],
                  
                  if (suspect.lies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Known Lies:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.bloodRed)),
                    ...suspect.lies.map((l) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• $l', style: AppTheme.evidenceText.copyWith(fontSize: 12, color: AppTheme.bloodRed)),
                    )),
                    _buildDetailRow(context, 'Motivation for Lying', suspect.motivationForLying),
                  ],
                ] else ...[
                  const Divider(color: AppTheme.noirLightGrey, height: 28),
                  Center(
                    child: Text(
                      'Additional details unlocked upon case resolution',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.paperDark.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.goldAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.evidenceText,
          ),
        ],
      ),
    );
  }
}