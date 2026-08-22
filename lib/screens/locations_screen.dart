import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../models/location.dart';
import '../models/clue.dart';
import '../game/investigation_engine.dart';
import '../utils/app_theme.dart';

class LocationsScreen extends StatelessWidget {
  final GameCase gameCase;
  final InvestigationEngine investigationEngine;
  final Function(Location) onLocationSelected;

  const LocationsScreen({
    super.key,
    required this.gameCase,
    required this.investigationEngine,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final crimeScene = gameCase.locations.firstWhere(
      (l) => l.isCrimeScene,
      orElse: () => gameCase.locations.first,
    );
    final otherLocations = gameCase.locations.where((l) => !l.isCrimeScene).toList();

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
                title: Text('LOCATIONS', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.goldAccent)),
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
              
              // Crime Scene Section
              SliverToBoxAdapter(
                child: _buildLocationSection(
                  context,
                  'CRIME SCENE',
                  [crimeScene],
                  AppTheme.bloodRed,
                  Icons.local_police_rounded,
                ),
              ),
             
              // Other Locations Section
              SliverToBoxAdapter(
                child: _buildLocationSection(
                  context,
                  'OTHER LOCATIONS',
                  otherLocations,
                  AppTheme.goldAccent,
                  Icons.location_on_rounded,
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

  Widget _buildLocationSection(BuildContext context, String title, List<Location> locations, Color accentColor, IconData icon) {
    if (locations.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${locations.length}',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            final isVisited = gameCase.isLocationVisited(location.id);
            final hasClues = location.clueIds.any((id) => !gameCase.isClueDiscovered(id));
            final availableClues = location.clueIds
                .map((id) => gameCase.getClue(id))
                .where((c) => c != null && !gameCase.isClueDiscovered(c!.id))
                .length;
            
            return _LocationCard(
              location: location,
              isVisited: isVisited,
              hasUndiscoveredClues: hasClues,
              undiscoveredCount: availableClues,
              accentColor: accentColor,
              onTap: () => onLocationSelected(location),
            );
          },
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Location location;
  final bool isVisited;
  final bool hasUndiscoveredClues;
  final int undiscoveredCount;
  final Color accentColor;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.isVisited,
    required this.hasUndiscoveredClues,
    required this.undiscoveredCount,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Location icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _getLocationIcon(location.name),
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            location.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.paperWhite,
                            ),
                          ),
                        ),
                        if (location.isCrimeScene)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.bloodRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CRIME SCENE',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.bloodRed,
                              ),
                            ),
                          ),
                        if (isVisited)
                          Icon(Icons.check_circle_rounded, color: AppTheme.mutedGreen, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (hasUndiscoveredClues)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppTheme.goldAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '$undiscoveredCount clues',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.goldAccent,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.paperDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Searched',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.paperDark,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (location.suspectIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.goldDark.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded, size: 12, color: AppTheme.goldDark),
                                const SizedBox(width: 4),
                                Text(
                                  '${location.suspectIds.length} suspects',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.goldDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('house') || lower.contains('home') || lower.contains('apartment')) return Icons.house_rounded;
    if (lower.contains('office') || lower.contains('work')) return Icons.work_rounded;
    if (lower.contains('restaurant') || lower.contains('diner') || lower.contains('cafe')) return Icons.restaurant_rounded;
    if (lower.contains('bar') || lower.contains('pub') || lower.contains('club')) return Icons.local_bar_rounded;
    if (lower.contains('park') || lower.contains('garden')) return Icons.park_rounded;
    if (lower.contains('warehouse') || lower.contains('storage') || lower.contains('factory')) return Icons.warehouse_rounded;
    if (lower.contains('hotel') || lower.contains('motel') || lower.contains('inn')) return Icons.hotel_rounded;
    if (lower.contains('street') || lower.contains('alley') || lower.contains('road')) return Icons.directions_rounded;
    if (lower.contains('crime') || lower.contains('scene')) return Icons.local_police_rounded;
    return Icons.location_on_rounded;
  }
}