// ============================================================
//  providers/recording_provider.dart
// ============================================================
//
//  Manages the STATE of the Audio Recorder module:
//  • List of recordings loaded from Supabase
//  • CRUD operations via DatabaseService
//
//  Note: Actual recording/playback logic lives in the
//  RecordScreen and PlaybackScreen (Part 5) because those
//  use platform plugins that need a BuildContext / lifecycle.
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/recording.dart';
import '../services/database_service.dart';

class RecordingProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // ── State ──────────────────────────────────────────────────
  List<Recording> _recordings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────
  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── LOAD ──────────────────────────────────────────────────
  Future<void> loadRecordings() async {
    _setLoading(true);
    try {
      _recordings = await _db.fetchRecordings();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── CREATE ─────────────────────────────────────────────────
  Future<bool> addRecording(Recording recording) async {
    _setLoading(true);
    try {
      final newRec = await _db.createRecording(recording);
      _recordings.insert(0, newRec);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── UPDATE title & notes ───────────────────────────────────
  Future<bool> updateRecording(Recording recording) async {
    _setLoading(true);
    try {
      final updated = await _db.updateRecording(recording);
      final index = _recordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) _recordings[index] = updated;
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────
  Future<bool> deleteRecording(String recordingId, String filePath) async {
    try {
      // Delete from storage first, then from DB
      await _db.deleteAudioFile(filePath);
      await _db.deleteRecording(recordingId);
      _recordings.removeWhere((r) => r.id == recordingId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── GET PLAYBACK URL ───────────────────────────────────────
  Future<String?> getPlaybackUrl(String filePath) async {
    try {
      return await _db.getAudioUrl(filePath);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
