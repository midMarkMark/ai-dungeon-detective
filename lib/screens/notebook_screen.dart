import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/clue.dart';
import '../models/timeline_event.dart';
import '../models/conversation_message.dart';
import '../game/contradiction_engine.dart';
import '../services/persistence_service.dart';
import '../utils/app_theme.dart';

class NotebookScreen extends StatefulWidget {
  final GameCase gameCase;

  const NotebookScreen({super.key, required this.gameCase});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ContradictionEngine _contradictionEngine;
  Map<String, List<Contradiction>> _allContradictions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final persistence = context.read<PersistenceService>();
    _contradictionEngine = ContradictionEngine(persistence);
    _analyzeContradictions();
  }

  void _analyzeContradictions() {
    _allContradictions = _contradictionEngine.getAllContradictions(widget.gameCase);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background paper texture
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A15),
              image: const DecorationImage(
                image: AssetImage('assets/images/paper_texture.png'),
                opacity: 0.03,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          
          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  AppTheme.noirBlack.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          
          // Content
          Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: AppTheme.noirDarkGrey.withValues(alpha: 0.95),
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
                          'DETECTIVE\'S NOTEBOOK',
                          style: AppTheme.noirTitle.copyWith(fontSize: 18),
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
                          'CASE: ${widget.gameCase.title}',
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
              
              // Tab Bar
              Container(
                color: AppTheme.noirDarkGrey.withValues(alpha: 0.95),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppTheme.goldAccent,
                  indicatorWeight: 3,
                  labelColor: AppTheme.goldAccent,
                  unselectedLabelColor: AppTheme.paperDark,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                  tabs: const [
                    Tab(text: 'CASE'),
                    Tab(text: 'SUSPECTS'),
                    Tab(text: 'EVIDENCE'),
                    Tab(text: 'TIMELINE'),
                    Tab(text: 'CONTRADICTIONS'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCaseTab(),
                    _buildSuspectsTab(),
                    _buildEvidenceTab(),
                    _buildTimelineTab(),
                    _buildContradictionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTab() {
    final c = widget.gameCase;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotebookSection('CASE OVERVIEW', [
            _buildInfoRow('Case Title', c.title),
            _buildInfoRow('Status', _getStatusText(c.status)),
            _buildInfoRow('Started', _formatDate(c.createdAt)),
            if (c.completedAt != null) _buildInfoRow('Completed', _formatDate(c.completedAt!)),
            _buildInfoRow('Play Time', _formatPlayTime(c.playTimeSeconds)),
          ]),
          
          const SizedBox(height: 20),
          _buildNotebookSection('VICTIM', [
            _buildInfoRow('Name', c.victim.name),
            _buildInfoRow('Age', '${c.victim.age}'),
            _buildInfoRow('Occupation', c.victim.occupation),
            _buildInfoRow('Description', c.victim.description),
          ]),
          
          const SizedBox(height: 20),
          _buildNotebookSection('CRIME DETAILS', [
            _buildInfoRow('Time of Death', c.murder.time),
            _buildInfoRow('Location', c.murder.location),
            _buildInfoRow('Weapon', c.murder.weapon),
            _buildInfoRow('Cause of Death', c.murder.causeOfDeath),
            _buildInfoRow('Method', c.murder.method),
            _buildInfoRow('Motive', c.murder.motive),
          ]),
          
          if (c.solutionSummary != null) ...[
            const SizedBox(height: 20),
            _buildNotebookSection('SOLUTION', [
              _buildInfoRow('Summary', c.solutionSummary!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSuspectsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.gameCase.suspects.length,
      itemBuilder: (context, index) {
        final suspect = widget.gameCase.suspects[index];
        final isInterrogated = widget.gameCase.isSuspectInterrogated(suspect.id);
        final conversation = widget.gameCase.getConversation(suspect.id);
        final contradictions = _allContradictions[suspect.id] ?? [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
              child: Text(
                suspect.name[0],
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    suspect.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.paperWhite,
                    ),
                  ),
                ),
                if (isInterrogated)
                  Icon(Icons.check_circle_rounded, color: AppTheme.mutedGreen, size: 20),
                if (contradictions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.warning_amber_rounded, color: AppTheme.bloodRed, size: 20),
                  ),
              ],
            ),
            subtitle: Text(
              '${suspect.age}  •  ${suspect.occupation}  •  ${suspect.personalityDisplayName}  •  ${conversation.length} messages',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Relationship to Victim', suspect.relationshipWithVictim),
                    _buildInfoRow('Personality', '${suspect.personalityDisplayName} - ${suspect.personalityDescription}'),
                    _buildInfoRow('Public Info', suspect.publicInfo),
                    if (widget.gameCase.status == CaseStatus.solved || widget.gameCase.status == CaseStatus.failed) ...[
                      const Divider(color: AppTheme.noirLightGrey),
                      _buildInfoRow('Private Info', suspect.privateInfo),
                      _buildInfoRow('Alibi', '${suspect.alibi} (${suspect.alibiTruthfulness.name})'),
                      _buildInfoRow('Motive', suspect.motive.isEmpty ? 'None apparent' : suspect.motive),
                      _buildInfoRow('Opportunity', suspect.hasOpportunity ? 'Yes - ${suspect.opportunityDetails}' : 'No clear opportunity'),
                      if (suspect.lies.isNotEmpty) ...[
                        const Divider(color: AppTheme.noirLightGrey),
                        Text('Known Lies:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                        ...suspect.lies.map((lie) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text('• $lie', style: AppTheme.evidenceText.copyWith(fontSize: 12)),
                        )),
                        _buildInfoRow('Motivation for Lying', suspect.motivationForLying),
                      ],
                    ],
                    if (contradictions.isNotEmpty) ...[
                      const Divider(color: AppTheme.noirLightGrey),
                      Text('⚠ Contradictions Detected:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.bloodRed)),
                      ...contradictions.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ${c.topic}: ${c.description}', style: AppTheme.evidenceText.copyWith(fontSize: 12, color: AppTheme.bloodRed)),
                            Text('  1. "${c.statement1}"', style: AppTheme.evidenceText.copyWith(fontSize: 11, color: AppTheme.paperDark)),
                            Text('  2. "${c.statement2}"', style: AppTheme.evidenceText.copyWith(fontSize: 11, color: AppTheme.paperDark)),
                          ],
                        ),
                      )),
                    ],
                    if (conversation.isNotEmpty) ...[
                      const Divider(color: AppTheme.noirLightGrey),
                      Text('Conversation Log (${conversation.length} messages)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                      ...conversation.take(5).map((msg) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${msg.role == MessageRole.detective ? 'You' : suspect.name}: ${msg.content.length > 80 ? '${msg.content.substring(0, 80)}...' : msg.content}',
                          style: AppTheme.evidenceText.copyWith(fontSize: 11),
                        ),
                      )),
                      if (conversation.length > 5)
                        Text('... and ${conversation.length - 5} more messages', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvidenceTab() {
    final discoveredClues = widget.gameCase.discoveredClues;
    final undiscoveredClues = widget.gameCase.undiscoveredClues;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Discovered clues
        if (discoveredClues.isNotEmpty) ...[
          _buildSectionHeader('DISCOVERED EVIDENCE (${discoveredClues.length})', AppTheme.mutedGreen),
          ...discoveredClues.map((clue) => _buildClueCard(clue, true)),
        ],
        
        if (discoveredClues.isNotEmpty && undiscoveredClues.isNotEmpty)
          const SizedBox(height: 24),
        
        // Undiscovered clues (hidden)
        if (widget.gameCase.status == CaseStatus.solved || widget.gameCase.status == CaseStatus.failed) ...[
          _buildSectionHeader('ALL CLUES (${undiscoveredClues.length} previously hidden)', AppTheme.goldAccent),
          ...undiscoveredClues.map((clue) => _buildClueCard(clue, false)),
        ] else if (undiscoveredClues.isNotEmpty) ...[
          _buildSectionHeader('UNDISCOVERED (${undiscoveredClues.length} remaining)', AppTheme.paperDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.paperDecoration,
            child: Text(
              'Continue investigating to uncover hidden clues. They will be revealed here once the case is solved.',
              style: AppTheme.evidenceText.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClueCard(Clue clue, bool discovered) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: discovered ? AppTheme.noirDarkGrey : AppTheme.noirMediumGrey.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getClueIcon(clue.type),
                    color: AppTheme.goldAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clue.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: discovered ? AppTheme.paperWhite : AppTheme.paperDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getImportanceColor(clue.importance).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    clue.importanceDisplayName,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _getImportanceColor(clue.importance),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              clue.description,
              style: AppTheme.evidenceText.copyWith(
                color: discovered ? AppTheme.paperWhite : AppTheme.paperDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(clue.typeDisplayName, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.noirMediumGrey,
                  side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (clue.isRedHerring)
                  Chip(
                    label: const Text('RED HERRING', style: TextStyle(fontSize: 10)),
                    backgroundColor: AppTheme.bloodRed.withValues(alpha: 0.15),
                    side: BorderSide(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            if (clue.isRedHerring && (widget.gameCase.status == CaseStatus.solved || widget.gameCase.status == CaseStatus.failed)) ...[
              const SizedBox(height: 8),
              Text(
                'Explanation: ${clue.redHerringExplanation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.bloodRed,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    final visibleEvents = widget.gameCase.timeline.where((t) => t.isPlayerVisible).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final allEvents = [...widget.gameCase.timeline]..sort((a, b) => a.time.compareTo(b.time));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (visibleEvents.isNotEmpty) ...[
          _buildSectionHeader('CONFIRMED TIMELINE (${visibleEvents.length})', AppTheme.mutedGreen),
          ...visibleEvents.map((event) => _buildTimelineCard(event, true)),
        ],
        
        if (widget.gameCase.status == CaseStatus.solved || widget.gameCase.status == CaseStatus.failed) ...[
          if (visibleEvents.isNotEmpty) const SizedBox(height: 24),
          _buildSectionHeader('FULL TIMELINE (${allEvents.length})', AppTheme.goldAccent),
          ...allEvents.map((event) => _buildTimelineCard(event, false)),
        ] else if (visibleEvents.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.paperDecoration,
            child: Column(
              children: [
                Icon(Icons.timeline_rounded, size: 48, color: AppTheme.goldAccent.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No Timeline Events Confirmed', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.paperWhite)),
                const SizedBox(height: 8),
                Text(
                  'Discover clues and interrogate suspects to build the timeline.',
                  style: AppTheme.evidenceText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineCard(TimelineEvent event, bool isConfirmed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.noirMediumGrey.withValues(alpha: isConfirmed ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfirmed 
            ? AppTheme.goldAccent.withValues(alpha: 0.3)
            : AppTheme.noirLightGrey.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getEventColor(event.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.noirBlack, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppTheme.noirLightGrey,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.time,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.typeDisplayName,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getEventColor(event.type),
                        ),
                      ),
                    ),
                    if (!isConfirmed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.paperDark.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HIDDEN',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.paperDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isConfirmed ? AppTheme.paperWhite : AppTheme.paperDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: AppTheme.evidenceText.copyWith(
                    color: isConfirmed ? AppTheme.paperDark : AppTheme.paperDark.withValues(alpha: 0.7),
                  ),
                ),
                if (event.supportingClueIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: event.supportingClueIds.map((clueId) {
                      final clue = widget.gameCase.getClue(clueId);
                      return Chip(
                        label: Text(clue?.name ?? clueId, style: const TextStyle(fontSize: 9)),
                        backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.1),
                        side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContradictionsTab() {
    final allContradictions = _allContradictions.values.expand((c) => c).toList()
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    if (allContradictions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: AppTheme.mutedGreen.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Contradictions Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.paperWhite),
              ),
              const SizedBox(height: 12),
              Text(
                'All suspect statements are consistent so far.\nKeep digging - everyone has something to hide.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allContradictions.length,
      itemBuilder: (context, index) {
        final c = allContradictions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: c.severity == ContradictionSeverity.high || c.severity == ContradictionSeverity.critical
            ? AppTheme.bloodRed.withValues(alpha: 0.1)
            : AppTheme.noirDarkGrey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      c.severity == ContradictionSeverity.critical ? Icons.dangerous_rounded :
                      c.severity == ContradictionSeverity.high ? Icons.warning_amber_rounded :
                      Icons.info_outline_rounded,
                      color: c.severity == ContradictionSeverity.low ? AppTheme.goldAccent : AppTheme.bloodRed,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${c.suspectName} - ${c.topic}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.severity == ContradictionSeverity.low ? AppTheme.goldAccent : AppTheme.bloodRed,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(c.severity).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.severity.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getSeverityColor(c.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(c.description, style: AppTheme.evidenceText),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.noirBlack.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statement 1:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                      Text('"${c.statement1}"', style: AppTheme.evidenceText.copyWith(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Statement 2:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                      Text('"${c.statement2}"', style: AppTheme.evidenceText.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotebookSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldAccent,
                letterSpacing: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.goldAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.evidenceText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor(ClueImportance importance) {
    switch (importance) {
      case ClueImportance.critical:
        return AppTheme.bloodRed;
      case ClueImportance.major:
        return AppTheme.goldAccent;
      case ClueImportance.minor:
        return AppTheme.mutedGreen;
      case ClueImportance.redHerring:
        return AppTheme.paperDark;
    }
  }

  Color _getEventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.murder:
        return AppTheme.bloodRed;
      case TimelineEventType.preMurder:
        return AppTheme.goldAccent;
      case TimelineEventType.postMurder:
        return AppTheme.mutedBlue;
      case TimelineEventType.alibi:
        return AppTheme.mutedGreen;
      case TimelineEventType.witness:
        return AppTheme.goldDark;
      case TimelineEventType.clueDiscovery:
        return AppTheme.mutedGreen;
      case TimelineEventType.suspiciousActivity:
        return AppTheme.bloodRed;
    }
  }

  Color _getSeverityColor(ContradictionSeverity severity) {
    switch (severity) {
      case ContradictionSeverity.low:
        return AppTheme.goldAccent;
      case ContradictionSeverity.medium:
        return AppTheme.goldDark;
      case ContradictionSeverity.high:
        return AppTheme.bloodRed;
      case ContradictionSeverity.critical:
        return AppTheme.bloodRed;
    }
  }

  String _getStatusText(CaseStatus status) {
    switch (status) {
      case CaseStatus.generated:
        return 'Generated';
      case CaseStatus.investigating:
        return 'Under Investigation';
      case CaseStatus.accused:
        return 'Accusation Made';
      case CaseStatus.solved:
        return 'Solved';
      case CaseStatus.failed:
        return 'Case Cold';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPlayTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  IconData _getClueIcon(ClueType type) {
    switch (type) {
      case ClueType.physical:
        return Icons.science_rounded;
      case ClueType.digital:
        return Icons.phone_android_rounded;
      case ClueType.testimonial:
        return Icons.record_voice_over_rounded;
      case ClueType.documentary:
        return Icons.description_rounded;
      case ClueType.forensic:
        return Icons.biotech_rounded;
      case ClueType.circumstantial:
        return Icons.extension_rounded;
    }
  }
}