// ============================================================
//  screens/recorder/record_screen.dart  –  Recording UI
// ============================================================
//
//  This screen has TWO phases controlled by _phase enum:
//
//  Phase 1: READY (before recording)
//  └── Large mic button → tapping starts recording
//
//  Phase 2: RECORDING (in progress)
//  └── Animated pulsing mic + live timer
//  └── Stop button → stops and moves to Phase 3
//
//  Phase 3: SAVING (after recording)
//  └── Form: title + notes fields
//  └── Save button → uploads to Supabase + saves metadata
//
//  Key Flutter concepts demonstrated:
//  • Timer (dart:async)       → updates the recording clock every second
//  • AnimationController      → drives the pulsing mic ring animation
//  • ValueNotifier            → lightweight state for the timer display
//  • async/await flow         → record → upload → db save → pop
//
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recording.dart';
import '../../providers/recording_provider.dart';
import '../../services/audio_service.dart';
import '../../utils/app_constants.dart';

// Enum to represent the three phases of this screen
enum _RecordPhase { ready, recording, saving }

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────
  final AudioService _audioService = AudioService();

  // ── Screen phase ──────────────────────────────────────────
  _RecordPhase _phase = _RecordPhase.ready;

  // ── Timer for live duration display ───────────────────────
  // Timer.periodic fires a callback every N duration
  Timer? _timer;
  int _elapsedSeconds = 0;  // How many seconds recorded so far

  // ── Result from stopRecording() ───────────────────────────
  RecordResult? _recordResult;

  // ── Save form ──────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  // ── Pulse animation for the recording ring ────────────────
  // AnimationController drives the animation timing
  late final AnimationController _pulseController;
  // Animation<double> maps the 0→1 controller value to 0.8→1.0 scale
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set up pulse animation: scale oscillates 0.85 ↔ 1.0
    // duration: 800ms per cycle, repeats indefinitely
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // repeat(reverse: true) → ping-pong: 0.85→1.0→0.85→...
    _pulseController.repeat(reverse: true);
    // Start paused — only plays during recording
    _pulseController.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Format seconds → "mm:ss" string ───────────────────────
  // Example: 75 → "1:15"
  String get _formattedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Start Recording ────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();

      setState(() {
        _phase = _RecordPhase.recording;
        _elapsedSeconds = 0;
      });

      // Start the visual timer — fires every 1 second
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });

      // Start the pulse animation
      _pulseController.repeat(reverse: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not start recording: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Stop Recording ─────────────────────────────────────────
  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();

    try {
      final result = await _audioService.stopRecording();
      setState(() {
        _recordResult = result;
        _phase = _RecordPhase.saving;
        // Pre-fill title with timestamp as default
        _titleController.text =
            'Recording ${DateTime.now().toString().substring(0, 16)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Stop failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        setState(() => _phase = _RecordPhase.ready);
      }
    }
  }

  // ── Cancel (discard the recording) ────────────────────────
  Future<void> _cancel() async {
    _timer?.cancel();
    _pulseController.stop();
    await _audioService.cancelRecording();
    setState(() {
      _phase = _RecordPhase.ready;
      _elapsedSeconds = 0;
      _recordResult = null;
    });
  }

  // ── Save recording to Supabase ─────────────────────────────
  Future<void> _saveRecording() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recordResult == null) return;

    setState(() => _isSaving = true);

    try {
      // Step 1: Upload audio file to Supabase Storage
      // This returns the storage path (e.g. "{userId}/{uuid}.m4a")
      final storagePath =
          await _audioService.uploadRecording(_recordResult!.localPath);

      // Step 2: Build the Recording model
      final recording = Recording(
        id: '',               // Server generates
        userId: '',           // Server fills from auth.uid()
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        filePath: storagePath,
        durationMs: _recordResult!.durationMs,
        createdAt: DateTime.now(),
      );

      // Step 3: Save metadata to the recordings table
      if (!mounted) return;
      final success =
          await context.read<RecordingProvider>().addRecording(recording);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Return to recording list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Recording saved!'),
        ));
      } else {
        throw Exception(
            context.read<RecordingProvider>().errorMessage ?? 'Save failed');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Discard without saving ────────────────────────────────
  Future<void> _discardSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text(
            'The audio file will be deleted. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (_recordResult != null) {
        try {
          await _audioService.cancelRecording();
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept back button during recording to prevent data loss
      canPop: _phase == _RecordPhase.ready,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _phase == _RecordPhase.recording) {
          await _cancel();
        } else if (!didPop && _phase == _RecordPhase.saving) {
          await _discardSave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_phase == _RecordPhase.saving
              ? 'Save Recording'
              : 'New Recording'),
          backgroundColor: ModuleColors.recorderLight,
          foregroundColor: ModuleColors.recorder,
        ),
        body: _phase == _RecordPhase.saving
            ? _buildSaveForm()
            : _buildRecordUI(),
      ),
    );
  }

  // ── Phase 1 & 2: Record UI ─────────────────────────────────
  Widget _buildRecordUI() {
    final theme = Theme.of(context);
    final isRecording = _phase == _RecordPhase.recording;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Status label ────────────────────────────────────
          Text(
            isRecording ? '● RECORDING' : 'TAP TO RECORD',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: isRecording
                  ? Colors.red
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Animated mic button ──────────────────────────────
          // ScaleTransition uses the _pulseAnimation to grow/shrink
          ScaleTransition(
            scale: isRecording
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: isRecording ? null : _startRecording,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Outer glow ring (only during recording)
                  border: isRecording
                      ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 12)
                      : null,
                  color: isRecording
                      ? Colors.red
                      : ModuleColors.recorder,
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording ? Colors.red : ModuleColors.recorder)
                          .withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Timer display ────────────────────────────────────
          Text(
            _formattedTime,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: isRecording ? Colors.red : theme.colorScheme.outline,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Stop button (only visible during recording) ──────
          if (isRecording)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop Recording',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _cancel,
                  child: Text('Cancel',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),

          // ── Hint (only on ready screen) ──────────────────────
          if (!isRecording)
            Text(
              'Tap the microphone to begin',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // ── Phase 3: Save Form ─────────────────────────────────────
  Widget _buildSaveForm() {
    final theme = Theme.of(context);
    final durationStr = _recordResult != null
        ? () {
            final s = _recordResult!.durationMs ~/ 1000;
            return '${ s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
          }()
        : '0:00';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Recorded summary card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: ModuleColors.recorderLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ModuleColors.recorder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recording Complete',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ModuleColors.recorder)),
                      Text('Duration: $durationStr',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: ModuleColors.recorder.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Title field ──────────────────────────────────
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Recording Title *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Notes field ──────────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.notes_rounded),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Save button ──────────────────────────────────
            _isSaving
                ? const Center(
                    child: Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Uploading & saving...',
                        style: TextStyle(color: Colors.grey)),
                  ]))
                : ElevatedButton.icon(
                    onPressed: _saveRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModuleColors.recorder,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Recording',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
            const SizedBox(height: AppSpacing.md),

            // ── Discard button ───────────────────────────────
            if (!_isSaving)
              OutlinedButton.icon(
                onPressed: _discardSave,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Discard'),
              ),
          ],
        ),
      ),
    );
  }
}