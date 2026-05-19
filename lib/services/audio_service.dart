// ============================================================
//  services/audio_service.dart  –  Recording & File Handling
// ============================================================
//
//  Updated for record v6.x API.
//
//  Key changes from record v5 → v6:
//  • AudioRecorder() now takes no positional arguments
//  • RecordConfig fields are the same but some defaults changed
//  • hasPermission() now accepts an optional {bool request}
//    named parameter — we call it without arguments (uses default)
//
// ============================================================

import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioService {
  // ── Singleton ──────────────────────────────────────────────
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // ── Dependencies ───────────────────────────────────────────
  // record v6: AudioRecorder() — no arguments needed
  final AudioRecorder _recorder = AudioRecorder();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ── State ──────────────────────────────────────────────────
  String? _currentFilePath;
  DateTime? _recordingStart;

  // ── Getters ────────────────────────────────────────────────
  String? get currentFilePath => _currentFilePath;

  // ── Check microphone permission ────────────────────────────
  // record v6: hasPermission() with no arguments uses default
  // {request: true} — prompts the user if not yet granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // ── Start Recording ────────────────────────────────────────
  Future<void> startRecording() async {
    if (!await hasPermission()) {
      throw Exception(
          'Microphone permission denied. Please allow in app settings.');
    }

    final fileName = '${_uuid.v4()}.m4a';
    final tempDir = await getTemporaryDirectory();
    _currentFilePath = '${tempDir.path}/$fileName';
    _recordingStart = DateTime.now();

    // record v6: start() signature unchanged
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: _currentFilePath!,
    );
  }

  // ── Stop Recording ─────────────────────────────────────────
  Future<RecordResult> stopRecording() async {
    final path = await _recorder.stop();

    final duration = _recordingStart != null
        ? DateTime.now().difference(_recordingStart!)
        : Duration.zero;

    _currentFilePath = null;
    _recordingStart = null;

    if (path == null) {
      throw Exception('Recording failed — no file was created.');
    }

    return RecordResult(
      localPath: path,
      durationMs: duration.inMilliseconds,
    );
  }

  // ── Cancel Recording ───────────────────────────────────────
  Future<void> cancelRecording() async {
    await _recorder.stop();
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) await file.delete();
    }
    _currentFilePath = null;
    _recordingStart = null;
  }

  // ── Is Currently Recording? ────────────────────────────────
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // ── Upload to Supabase Storage ─────────────────────────────
  Future<String> uploadRecording(String localPath) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found at: $localPath');
    }

    final fileName = localPath.split('/').last;
    final storagePath = '${user.id}/$fileName';
    final bytes = await file.readAsBytes();

    await _supabase.storage.from('recordings').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/mp4',
            upsert: false,
          ),
        );

    await file.delete();
    return storagePath;
  }

  // ── Get Signed Playback URL ────────────────────────────────
  Future<String> getPlaybackUrl(String storagePath) async {
    return await _supabase.storage
        .from('recordings')
        .createSignedUrl(storagePath, 3600);
  }

  // ── Delete from Storage ────────────────────────────────────
  Future<void> deleteFromStorage(String storagePath) async {
    try {
      await _supabase.storage.from('recordings').remove([storagePath]);
    } catch (_) {}
  }

  // ── Dispose ───────────────────────────────────────────────
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

// ── RecordResult ──────────────────────────────────────────────
class RecordResult {
  final String localPath;
  final int durationMs;

  const RecordResult({
    required this.localPath,
    required this.durationMs,
  });
}