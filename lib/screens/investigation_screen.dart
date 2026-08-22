import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../models/suspect.dart';
import '../models/clue.dart';
import '../models/location.dart';
import '../models/conversation_message.dart';
import '../game/investigation_engine.dart';
import '../services/persistence_service.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import 'notebook_screen.dart';
import 'suspects_screen.dart';
import 'locations_screen.dart';
import 'accusation_screen.dart';

class InvestigationScreen extends StatefulWidget {
  final GameCase gameCase;

  const InvestigationScreen({super.key, required this.gameCase});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late InvestigationEngine _engine;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  int _selectedTab = 0; // 0: Interrogate, 1: Locations, 2: Evidence
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isLoading = false;
  String? _currentActionContext; // For location investigation actions
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final aiService = context.read<QuillBotService>();
    final persistence = context.read<PersistenceService>();
    _engine = InvestigationEngine(aiService, persistence);
    _engine.setCurrentCase(widget.gameCase);
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack);
    _fabController.forward();
    
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _engine.updatePlayTime(30);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _engine.updatePlayTime(30);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputController.dispose();
    _chatScrollController.dispose();
    _fabController.dispose();
    _autoSaveTimer?.cancel();
    _engine.clearCurrentCase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersistenceService>(
      builder: (context, persistence, _) {
        final gameCase = persistence.currentCase ?? widget.gameCase;
        
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
              
              // Main layout
              Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(gameCase),
                  
                  // Tab Bar
                  _buildTabBar(),
                  
                  // Tab Content
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        _buildInterrogateTab(gameCase),
                        _buildLocationsTab(gameCase),
                        _buildEvidenceTab(gameCase),
                      ],
                    ),
                  ),
                  
                  // Input Area (only for interrogate tab)
                  if (_selectedTab == 0) _buildInputArea(),
                ],
              ),
              
              // FAB for quick actions
              _buildFab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(GameCase gameCase) {
    return Container(
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
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.goldAccent),
              onPressed: () => _showExitDialog(),
            ),
            
            // Case title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameCase.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${gameCase.suspects.length} suspects  •  ${gameCase.discoveredClueIds.length}/${gameCase.clues.length} clues  •  ${gameCase.interrogatedSuspectIds.length} interrogated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.paperDark,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
            ),
            
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(gameCase.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(gameCase.status).withValues(alpha: 0.3)),
              ),
              child: Text(
                _getStatusText(gameCase.status),
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(gameCase.status),
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.goldAccent),
              color: AppTheme.noirDarkGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
              ),
              onSelected: (value) => _handleMenuAction(value, gameCase),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'notebook',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppTheme.goldAccent, size: 20),
                      const SizedBox(width: 12),
                      const Text('Notebook'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'suspects',
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, color: AppTheme.goldAccent, size: 20),
                      const SizedBox(width: 12),
                      const Text('Suspect Profiles'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'accuse',
                  child: Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: AppTheme.bloodRed, size: 20),
                      const SizedBox(width: 12),
                      Text('Make Accusation', style: TextStyle(color: AppTheme.bloodRed)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_rounded, color: AppTheme.goldAccent, size: 20),
                      const SizedBox(width: 12),
                      const Text('Save & Exit'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.generated:
        return AppTheme.goldAccent;
      case CaseStatus.investigating:
        return AppTheme.mutedGreen;
      case CaseStatus.accused:
        return AppTheme.bloodRed;
      case CaseStatus.solved:
        return AppTheme.goldAccent;
      case CaseStatus.failed:
        return AppTheme.bloodRed;
    }
  }

  String _getStatusText(CaseStatus status) {
    switch (status) {
      case CaseStatus.generated:
        return 'NEW';
      case CaseStatus.investigating:
        return 'ACTIVE';
      case CaseStatus.accused:
        return 'ACCUSED';
      case CaseStatus.solved:
        return 'SOLVED';
      case CaseStatus.failed:
        return 'COLD';
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey,
        border: Border(
          bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: TabController(length: 3, vsync: this, initialIndex: _selectedTab),
        onTap: (index) => setState(() => _selectedTab = index),
        indicatorColor: AppTheme.goldAccent,
        indicatorWeight: 3,
        labelColor: AppTheme.goldAccent,
        unselectedLabelColor: AppTheme.paperDark,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.chat_rounded, size: 20), text: 'INTERROGATE'),
          Tab(icon: Icon(Icons.location_on_rounded, size: 20), text: 'LOCATIONS'),
          Tab(icon: Icon(Icons.verified_rounded, size: 20), text: 'EVIDENCE'),
        ],
      ),
    );
  }

  Widget _buildInterrogateTab(GameCase gameCase) {
    final suspect = _engine.currentSuspectId != null 
      ? gameCase.getSuspect(_engine.currentSuspectId!) 
      : null;
    final conversation = suspect != null 
      ? (gameCase.getConversation(suspect.id) as List<ConversationMessage>)
      : <ConversationMessage>[];

    return Column(
      children: [
        // Current suspect header
        if (suspect != null) _buildSuspectHeader(suspect, gameCase),
        
        // Conversation area
        Expanded(
          child: conversation.isEmpty && suspect == null
            ? _buildNoSuspectSelected()
            : conversation.isEmpty
              ? _buildStartConversation(suspect!)
              : _buildConversationList(conversation, suspect!),
        ),
      ],
    );
  }

  Widget _buildSuspectHeader(Suspect suspect, GameCase gameCase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey,
        border: Border(
          bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.goldAccent.withValues(alpha: 0.3), AppTheme.goldDark.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                suspect.name[0],
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent,
                ),
              ),
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
                    Text(
                      suspect.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.paperWhite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        suspect.personalityDisplayName,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${suspect.age}  •  ${suspect.occupation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                ),
                Text(
                  suspect.relationshipWithVictim,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.goldAccent.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Change suspect button
          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('SWITCH'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _showSuspectSelector(gameCase),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuspectSelected() {
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
                Icons.person_search_rounded,
                size: 64,
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Suspect Selected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.paperWhite),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a suspect from the menu or the Suspects tab to begin interrogation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.people_rounded),
              label: const Text('VIEW SUSPECTS'),
              onPressed: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartConversation(Suspect suspect) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '"..."',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 32,
                  color: AppTheme.goldAccent.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Interrogating ${suspect.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.paperWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Type your question below to begin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.paperDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suggested Openers:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent)),
                  const SizedBox(height: 8),
                  ...[
                    '"Where were you at the time of the murder?"',
                    '"What was your relationship with the victim?"',
                    '"Do you know the other suspects?"',
                    '"Did you notice anything unusual that night?"',
                  ].map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      s,
                      style: AppTheme.evidenceText.copyWith(fontSize: 12),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(List<ConversationMessage> conversation, Suspect suspect) {
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: conversation.length,
      itemBuilder: (context, index) {
        final message = conversation[conversation.length - 1 - index];
        return _buildMessageBubble(message, suspect);
      },
    );
  }

  Widget _buildMessageBubble(ConversationMessage message, Suspect suspect) {
    final isDetective = message.role == MessageRole.detective;
    
    return Align(
      alignment: isDetective ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isDetective ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isDetective) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suspect.name,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (message.isImportant) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.flag_rounded, size: 12, color: AppTheme.bloodRed),
                  ],
                  if (message.contradictionNote != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.bloodRed),
                  ],
                ],
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDetective 
                  ? AppTheme.goldAccent.withValues(alpha: 0.15)
                  : AppTheme.noirMediumGrey,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isDetective ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isDetective ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isDetective 
                    ? AppTheme.goldAccent.withValues(alpha: 0.3)
                    : message.isImportant 
                      ? AppTheme.bloodRed.withValues(alpha: 0.5)
                      : AppTheme.noirLightGrey,
                ),
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDetective ? AppTheme.paperWhite : AppTheme.paperWhite,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppTheme.paperDark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey,
        border: Border(
          top: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperWhite),
                decoration: InputDecoration(
                  hintText: 'Ask your question...',
                  hintStyle: TextStyle(color: AppTheme.paperDark.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.noirLightGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.noirLightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.goldAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.noirMediumGrey,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  prefixIcon: Icon(Icons.mic_none_rounded, color: AppTheme.goldAccent.withValues(alpha: 0.5)),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: _isLoading ? null : _sendMessage,
              ),
            ),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: _isLoading ? null : () => _sendMessage(_inputController.text),
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.noirBlack,
                mini: true,
                child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.noirBlack),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _engine.currentSuspectId == null) return;
    
    final question = text.trim();
    _inputController.clear();
    setState(() => _isLoading = true);
    
    // Add detective message
    await _engine.addConversationMessage(
      _engine.currentSuspectId!,
      MessageRole.detective,
      question,
    );
    
    // Scroll to bottom
    _scrollToBottom();
    
    // Get suspect response
    final response = await _engine.askSuspect(question);
    
    if (response != null && mounted) {
      await _engine.addConversationMessage(
        _engine.currentSuspectId!,
        MessageRole.suspect,
        response,
      );
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Widget _buildLocationsTab(GameCase gameCase) {
    return LocationsScreen(
      gameCase: gameCase,
      investigationEngine: _engine,
      onLocationSelected: (location) => _showLocationActions(location),
    );
  }

  Widget _buildEvidenceTab(GameCase gameCase) {
    return _EvidenceTab(
      gameCase: gameCase,
      onClueTap: (clue) => _showClueDetail(clue),
    );
  }

  Widget _buildFab() {
    return Positioned(
      right: 20,
      bottom: _selectedTab == 0 ? 100 : 20,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          backgroundColor: AppTheme.goldAccent,
          foregroundColor: AppTheme.noirBlack,
          onPressed: () => _showQuickActions(),
          child: const Icon(Icons.flash_on_rounded),
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.noirDarkGrey,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.noirLightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.menu_book_rounded, color: AppTheme.goldAccent),
              title: Text('Open Notebook', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotebookScreen(gameCase: _engine.currentCase!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.people_rounded, color: AppTheme.goldAccent),
              title: Text('Suspect Profiles', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SuspectsScreen(gameCase: _engine.currentCase!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.gavel_rounded, color: AppTheme.bloodRed),
              title: Text('Make Accusation', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.bloodRed)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AccusationScreen(gameCase: _engine.currentCase!)));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSuspectSelector(GameCase gameCase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SuspectSelectorSheet(
        gameCase: gameCase,
        currentSuspectId: _engine.currentSuspectId,
        onSelect: (suspectId) async {
          Navigator.pop(context);
          await _engine.startInterrogation(suspectId);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showLocationActions(Location location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LocationActionSheet(
        location: location,
        gameCase: _engine.currentCase!,
        onAction: (action) async {
          Navigator.pop(context);
          await _performLocationAction(action);
        },
      ),
    );
  }

  Future<void> _performLocationAction(String action) async {
    if (_engine.currentLocationId == null) return;
    
    setState(() => _isLoading = true);
    final result = await _engine.investigateLocation(action);
    
    if (result != null && mounted) {
      // Check if any clues were discovered
      final availableClues = _engine.getAvailableCluesAtCurrentLocation();
      for (final clue in availableClues) {
        if (result.toLowerCase().contains(clue.name.toLowerCase()) || 
            result.toLowerCase().contains(clue.requiredAction.toLowerCase())) {
          await _engine.discoverClue(clue.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CLUE DISCOVERED: ${clue.name}'),
                backgroundColor: AppTheme.mutedGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      
      // Show result
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.search_rounded, color: AppTheme.goldAccent),
                const SizedBox(width: 8),
                const Text('Investigation Result'),
              ],
            ),
            content: Text(result, style: AppTheme.evidenceText),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CONTINUE'),
              ),
            ],
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _showClueDetail(Clue clue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.noirDarkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(_getClueIcon(clue.type), color: AppTheme.goldAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(clue.name, style: Theme.of(context).textTheme.titleMedium)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.paperDecoration,
              child: Text(clue.description, style: AppTheme.evidenceText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(clue.typeDisplayName, style: const TextStyle(fontSize: 11)),
                  avatar: Icon(_getClueIcon(clue.type), size: 14),
                  backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.1),
                  side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                ),
                Chip(
                  label: Text(clue.importanceDisplayName, style: const TextStyle(fontSize: 11)),
                  backgroundColor: clue.importance == ClueImportance.critical 
                    ? AppTheme.bloodRed.withValues(alpha: 0.1)
                    : AppTheme.goldAccent.withValues(alpha: 0.1),
                  side: BorderSide(color: clue.importance == ClueImportance.critical 
                    ? AppTheme.bloodRed.withValues(alpha: 0.3)
                    : AppTheme.goldAccent.withValues(alpha: 0.3)),
                ),
                if (clue.isRedHerring)
                  Chip(
                    label: const Text('RED HERRING', style: TextStyle(fontSize: 11)),
                    avatar: Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.bloodRed),
                    backgroundColor: AppTheme.bloodRed.withValues(alpha: 0.1),
                    side: BorderSide(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
                  ),
              ],
            ),
            if (clue.isRedHerring) ...[
              const SizedBox(height: 12),
              Text(
                'Note: ${clue.redHerringExplanation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.bloodRed,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
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

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.noirDarkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppTheme.goldAccent),
            const SizedBox(width: 12),
            const Text('Exit Investigation'),
          ],
        ),
        content: const Text('Your progress will be saved automatically. Return to the main menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bloodRed),
            child: const Text('EXIT'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, GameCase gameCase) {
    switch (action) {
      case 'notebook':
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotebookScreen(gameCase: gameCase)));
        break;
      case 'suspects':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SuspectsScreen(gameCase: gameCase)));
        break;
      case 'accuse':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AccusationScreen(gameCase: gameCase)));
        break;
      case 'save':
        Navigator.pop(context);
        break;
    }
  }
}

class _EvidenceTab extends StatelessWidget {
  final GameCase gameCase;
  final Function(Clue) onClueTap;

  const _EvidenceTab({required this.gameCase, required this.onClueTap});

  @override
  Widget build(BuildContext context) {
    final discoveredClues = gameCase.discoveredClues;
    final undiscoveredCount = gameCase.undiscoveredClues.length;

    if (discoveredClues.isEmpty) {
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
                  Icons.verified_outlined,
                  size: 64,
                  color: AppTheme.goldAccent.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Evidence Collected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.paperWhite),
              ),
              const SizedBox(height: 12),
              Text(
                'Investigate locations and interrogate suspects to discover clues.\n$undiscoveredCount clues remain hidden.',
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
      itemCount: discoveredClues.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'DISCOVERED: ${discoveredClues.length}/${gameCase.clues.length}',
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
          );
        }
        final clue = discoveredClues[index - 1];
        return _ClueCard(clue: clue, onTap: () => onClueTap(clue));
      },
    );
  }
}

class _ClueCard extends StatelessWidget {
  final Clue clue;
  final VoidCallback onTap;

  const _ClueCard({required this.clue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        color: AppTheme.paperWhite,
                      ),
                    ),
                  ),
                  if (clue.isRedHerring)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bloodRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'RED HERRING',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.bloodRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                clue.description,
                style: AppTheme.evidenceText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                  Chip(
                    label: Text(clue.importanceDisplayName, style: const TextStyle(fontSize: 10)),
                    backgroundColor: clue.importance == ClueImportance.critical
                      ? AppTheme.bloodRed.withValues(alpha: 0.15)
                      : AppTheme.noirMediumGrey,
                    side: BorderSide(color: clue.importance == ClueImportance.critical
                      ? AppTheme.bloodRed.withValues(alpha: 0.3)
                      : AppTheme.goldAccent.withValues(alpha: 0.2)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _SuspectSelectorSheet extends StatelessWidget {
  final GameCase gameCase;
  final String? currentSuspectId;
  final Function(String) onSelect;

  const _SuspectSelectorSheet({
    required this.gameCase,
    required this.currentSuspectId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.noirLightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('SELECT SUSPECT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.goldAccent)),
                const Spacer(),
                Text('${gameCase.suspects.length} suspects', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: gameCase.suspects.length,
              itemBuilder: (context, index) {
                final suspect = gameCase.suspects[index];
                final isCurrent = suspect.id == currentSuspectId;
                final isInterrogated = gameCase.isSuspectInterrogated(suspect.id);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.2),
                    child: Text(
                      suspect.name[0],
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? AppTheme.noirBlack : AppTheme.goldAccent,
                      ),
                    ),
                  ),
                  title: Text(suspect.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isCurrent ? AppTheme.goldAccent : AppTheme.paperWhite,
                  )),
                  subtitle: Text(
                    '${suspect.age}  •  ${suspect.occupation}  •  ${suspect.personalityDisplayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isInterrogated)
                        Icon(Icons.check_circle_rounded, color: AppTheme.mutedGreen, size: 20),
                      if (isCurrent)
                        Icon(Icons.mic_rounded, color: AppTheme.goldAccent, size: 20),
                    ],
                  ),
                  onTap: () => onSelect(suspect.id),
                  selected: isCurrent,
                  selectedTileColor: AppTheme.goldAccent.withValues(alpha: 0.05),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationActionSheet extends StatelessWidget {
  final Location location;
  final GameCase gameCase;
  final Function(String) onAction;

  const _LocationActionSheet({
    required this.location,
    required this.gameCase,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      'Search the area thoroughly',
      'Look for fingerprints',
      'Check for hidden compartments',
      'Examine the floor for footprints',
      'Look around the room',
      'Check the window/doors',
      'Search drawers and cabinets',
      'Look for any documents',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.noirDarkGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.noirLightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on_rounded, color: AppTheme.goldAccent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.paperWhite)),
                          Text(location.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark)),
                        ],
                      ),
                    ),
                    if (location.isCrimeScene)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bloodRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CRIME SCENE',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.bloodRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.noirLightGrey),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.search_rounded, color: AppTheme.goldAccent.withValues(alpha: 0.7)),
                  title: Text(actions[index], style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => onAction(actions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}