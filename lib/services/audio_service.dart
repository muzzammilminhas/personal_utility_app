import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  String? _currentFilePath;
  DateTime? _recordingStart;

  String? get currentFilePath => _currentFilePath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) {
      throw Exception(
          'Microphone permission denied. Please allow in app settings.');
    }

    final fileName = '${_uuid.v4()}.m4a';
    final tempDir = await getTemporaryDirectory();
    _currentFilePath = '${tempDir.path}/$fileName';
    _recordingStart = DateTime.now();

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

  Future<void> cancelRecording() async {
    await _recorder.stop();
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) await file.delete();
    }
    _currentFilePath = null;
    _recordingStart = null;
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

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

  Future<String> getPlaybackUrl(String storagePath) async {
    return await _supabase.storage
        .from('recordings')
        .createSignedUrl(storagePath, 3600);
  }

  Future<void> deleteFromStorage(String storagePath) async {
    try {
      await _supabase.storage.from('recordings').remove([storagePath]);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

class RecordResult {
  final String localPath;
  final int durationMs;

  const RecordResult({
    required this.localPath,
    required this.durationMs,
  });
}
