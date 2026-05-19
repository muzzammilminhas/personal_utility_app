// ============================================================
//  screens/recorder/edit_recording_screen.dart  –  Edit Metadata
// ============================================================
//
//  Allows the user to update the title and notes of a saved
//  recording. The audio file itself is NOT changed — only the
//  metadata stored in the Supabase `recordings` table.
//
//  This is a straightforward edit form that mirrors the pattern
//  used in CardFormScreen (Part 3) with the same Provider → DB
//  update flow.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recording.dart';
import '../../providers/recording_provider.dart';
import '../../utils/app_constants.dart';

class EditRecordingScreen extends StatefulWidget {
  final Recording recording;

  const EditRecordingScreen({super.key, required this.recording});

  @override
  State<EditRecordingScreen> createState() => _EditRecordingScreenState();
}

class _EditRecordingScreenState extends State<EditRecordingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing values
    _titleController = TextEditingController(text: widget.recording.title);
    _notesController = TextEditingController(text: widget.recording.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Build updated Recording using copyWith
    final updated = widget.recording.copyWith(
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final success =
        await context.read<RecordingProvider>().updateRecording(updated);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording updated!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            context.read<RecordingProvider>().errorMessage ?? 'Update failed'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordingProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recording'),
        backgroundColor: ModuleColors.recorderLight,
        foregroundColor: ModuleColors.recorder,
        actions: [
          TextButton(
            onPressed: provider.isLoading ? null : _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: provider.isLoading
                    ? theme.colorScheme.outline
                    : ModuleColors.recorder,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // ── Duration info (read-only) ──────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: ModuleColors.recorderLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: ModuleColors.recorder),
                    const SizedBox(width: 10),
                    Text(
                      'Duration: ${widget.recording.formattedDuration}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ModuleColors.recorder,
                        fontWeight: FontWeight.w500,
                      ),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Notes field ──────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.notes_rounded),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Save button ──────────────────────────────────
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModuleColors.recorder,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
