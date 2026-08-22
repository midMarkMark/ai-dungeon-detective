import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../services/persistence_service.dart';
import '../utils/app_theme.dart';

class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  State<CaseHistoryScreen> createState() => _CaseHistoryScreenState();
}

class _CaseHistoryScreenState extends State<CaseHistoryScreen> with TickerProviderStateMixin {
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
        final history = persistence.caseHistory;

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
                                  'CASE HISTORY',
                                  style: AppTheme.noirTitle.copyWith(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (history.isNotEmpty)
                                TextButton.icon(
                                  icon: Icon(Icons.delete_sweep_rounded, color: AppTheme.bloodRed, size: 18),
                                  label: Text('CLEAR ALL', style: TextStyle(color: AppTheme.bloodRed)),
                                  onPressed: () => _showClearDialog(persistence),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: history.isEmpty
                          ? _buildEmptyState()
                          : _buildHistoryList(history),
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

  Widget _buildEmptyState() {
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
                Icons.folder_open_rounded,
                size: 64,
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Cases Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.paperWhite),
            ),
            const SizedBox(height: 12),
            Text(
              'Your case history will appear here after you complete investigations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.paperDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START FIRST CASE'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<CaseSummary> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final caseSummary = history[index];
        return _HistoryCard(caseSummary: caseSummary, onDelete: () => _deleteCase(caseSummary.id));
      },
    );
  }

  Widget _buildHistoryCard(CaseSummary caseSummary, VoidCallback onDelete) {
    // This method is not used, the _HistoryCard widget is used instead
    return const SizedBox.shrink();
  }

  void _showClearDialog(PersistenceService persistence) {
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
            const Text('Clear All Cases'),
          ],
        ),
        content: const Text('This will permanently delete all case history. This action cannot be undone.'),
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

  void _deleteCase(String caseId) {
    final persistence = context.read<PersistenceService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.noirDarkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.bloodRed.withValues(alpha: 0.3)),
        ),
        title: const Text('Delete Case'),
        content: const Text('Remove this case from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              persistence.removeFromHistory(caseId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bloodRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CaseSummary caseSummary;
  final VoidCallback onDelete;

  const _HistoryCard({required this.caseSummary, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSolved = caseSummary.solved;
    final isCorrect = caseSummary.correctAccusation;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCaseDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(isSolved, isCorrect).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(isSolved, isCorrect).withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      _getStatusIcon(isSolved, isCorrect),
                      color: _getStatusColor(isSolved, isCorrect),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseSummary.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.paperWhite,
                          ),
                        ),
                        Text(
                          'Victim: ${caseSummary.victimName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.paperDark),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getStatusText(isSolved, isCorrect),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(isSolved, isCorrect),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(caseSummary.startedAt),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: AppTheme.paperDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.bloodRed.withValues(alpha: 0.7), size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  _buildStatChip('${caseSummary.suspectsCount} Suspects', Icons.people_rounded),
                  const SizedBox(width: 8),
                  _buildStatChip('${caseSummary.cluesFound}/${caseSummary.suspectsCount * 2} Clues', Icons.verified_rounded),
                  const SizedBox(width: 8),
                  _buildStatChip('${caseSummary.playTimeMinutes} min', Icons.timer_rounded),
                ],
              ),
              
              if (isSolved && caseSummary.murdererName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.mutedGreen.withValues(alpha: 0.1) : AppTheme.bloodRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCorrect ? AppTheme.mutedGreen.withValues(alpha: 0.3) : AppTheme.bloodRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? AppTheme.mutedGreen : AppTheme.bloodRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect 
                          ? 'Correctly identified ${caseSummary.murdererName} as the murderer'
                          : 'Incorrectly accused ${caseSummary.murdererName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCorrect ? AppTheme.mutedGreen : AppTheme.bloodRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.noirMediumGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.noirLightGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.goldAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.paperDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool solved, bool correct) {
    if (!solved) return AppTheme.goldAccent;
    return correct ? AppTheme.mutedGreen : AppTheme.bloodRed;
  }

  IconData _getStatusIcon(bool solved, bool correct) {
    if (!solved) return Icons.hourglass_empty_rounded;
    return correct ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }

  String _getStatusText(bool solved, bool correct) {
    if (!solved) return 'IN PROGRESS';
    return correct ? 'SOLVED' : 'FAILED';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCaseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.noirDarkGrey,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseSummary.title, style: AppTheme.noirTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Victim', caseSummary.victimName),
                  _buildDetailRow(context, 'Started', _formatDateTime(caseSummary.startedAt)),
                  if (caseSummary.completedAt != null)
                    _buildDetailRow(context, 'Completed', _formatDateTime(caseSummary.completedAt!)),
                  _buildDetailRow(context, 'Status', _getStatusText(caseSummary.solved, caseSummary.correctAccusation)),
                  _buildDetailRow(context, 'Play Time', '${caseSummary.playTimeMinutes} minutes'),
                  _buildDetailRow(context, 'Suspects', '${caseSummary.suspectsCount}'),
                  _buildDetailRow(context, 'Clues Found', '${caseSummary.cluesFound}'),
                  if (caseSummary.murdererName != null)
                    _buildDetailRow(context, 'Murderer', caseSummary.murdererName!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.goldAccent),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTheme.evidenceText),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}