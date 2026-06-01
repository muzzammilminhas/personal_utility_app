import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/recording.dart';
import '../../providers/recording_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import 'record_screen.dart';
import 'playback_screen.dart';
import 'edit_recording_screen.dart';

class RecordingListScreen extends StatefulWidget {
  const RecordingListScreen({super.key});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordingProvider>().loadRecordings();
    });
  }

  void _openRecordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordScreen()),
    ).then((_) {
      if (mounted) context.read<RecordingProvider>().loadRecordings();
    });
  }

  void _openPlayback(Recording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaybackScreen(recording: recording)),
    );
  }

  void _openEdit(Recording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditRecordingScreen(recording: recording)),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Recording',
      message: 'Delete "${recording.title}"? This cannot be undone.',
    );
    if (confirmed && mounted) {
      final success = await context
          .read<RecordingProvider>()
          .deleteRecording(recording.id, recording.filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '"${recording.title}" deleted'
              : 'Delete failed. Try again.'),
          backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recordings'),
        backgroundColor: ModuleColors.recorderLight,
        foregroundColor: ModuleColors.recorder,
      ),
      body: Consumer<RecordingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(label: 'Loading recordings...');
          }
          if (provider.errorMessage != null) {
            return ErrorDisplay(
              message: provider.errorMessage!,
              onRetry: provider.loadRecordings,
            );
          }
          if (provider.recordings.isEmpty) {
            return EmptyState(
              icon: Icons.mic_none_rounded,
              title: 'No Recordings Yet',
              message:
                  'Tap the mic button below to record your first audio note.',
              buttonLabel: 'Start Recording',
              onButtonPressed: _openRecordScreen,
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadRecordings,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.recordings.length,
              itemBuilder: (_, index) {
                final rec = provider.recordings[index];
                return _RecordingTile(
                  recording: rec,
                  onTap: () => _openPlayback(rec),
                  onEdit: () => _openEdit(rec),
                  onDelete: () => _deleteRecording(rec),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordScreen,
        backgroundColor: ModuleColors.recorder,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_rounded),
        label: const Text('New Recording'),
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final Recording recording;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordingTile({
    required this.recording,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ModuleColors.recorderLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.play_circle_filled_rounded,
                    color: ModuleColors.recorder, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recording.notes.isNotEmpty)
                      Text(
                        recording.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(
                          Icons.timer_outlined,
                          recording.formattedDuration,
                          theme,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _badge(
                          Icons.calendar_today_outlined,
                          DateFormat('MMM d, yyyy').format(recording.createdAt),
                          theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'play') onTap();
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: ListTile(
                        leading: Icon(Icons.play_arrow_rounded),
                        title: Text('Play'),
                        dense: true,
                        contentPadding: EdgeInsets.zero),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        dense: true,
                        contentPadding: EdgeInsets.zero),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                        dense: true,
                        contentPadding: EdgeInsets.zero),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ModuleColors.recorderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ModuleColors.recorder),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: ModuleColors.recorder,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
