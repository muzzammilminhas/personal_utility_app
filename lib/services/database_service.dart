// ============================================================
//  services/database_service.dart  –  Supabase CRUD Operations
// ============================================================
//
//  The SERVICE LAYER is where all database calls live.
//  Keeping DB logic here (not in screens or providers) means:
//  • Screens stay simple — they only call service methods
//  • Easy to change or fix DB logic in one place
//  • Code is reusable across multiple providers/screens
//
//  This service handles ALL three modules:
//  ① Business Cards  ② Scan History  ③ Recordings
//
//  Every method:
//  • Is async (returns a Future) because network calls take time
//  • Uses try/catch to handle errors gracefully
//  • Filters by user_id automatically (RLS does this too,
//    but we filter explicitly for clarity)
//
// ============================================================

import 'dart:io'; // dart:io File class
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_card.dart';
import '../models/scan_history.dart';
import '../models/recording.dart';

class AdminDashboardData {
  final int totalCards;
  final int totalRecordings;
  final int totalScans;
  final int totalKnownUsers;
  final List<Map<String, dynamic>> recentCards;
  final List<Map<String, dynamic>> recentRecordings;
  final List<Map<String, dynamic>> recentScans;

  const AdminDashboardData({
    required this.totalCards,
    required this.totalRecordings,
    required this.totalScans,
    required this.totalKnownUsers,
    required this.recentCards,
    required this.recentRecordings,
    required this.recentScans,
  });
}

class DatabaseService {
  // ── Supabase client singleton ──────────────────────────────
  final SupabaseClient _db = Supabase.instance.client;

  // ── Helper: get current user's ID ─────────────────────────
  String get _userId {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    return user.id;
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 1: BUSINESS CARDS
  // ════════════════════════════════════════════════════════════

  Future<List<BusinessCard>> fetchBusinessCards() async {
    try {
      final response = await _db
          .from('business_cards')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => BusinessCard.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch business cards: $e');
    }
  }

  Future<BusinessCard> createBusinessCard(BusinessCard card) async {
    try {
      final response = await _db
          .from('business_cards')
          .insert({
            'user_id': _userId,
            ...card.toJson(),
          })
          .select()
          .single();

      return BusinessCard.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create business card: $e');
    }
  }

  Future<BusinessCard> updateBusinessCard(BusinessCard card) async {
    try {
      final response = await _db
          .from('business_cards')
          .update(card.toJson())
          .eq('id', card.id)
          .eq('user_id', _userId)
          .select()
          .single();

      return BusinessCard.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update business card: $e');
    }
  }

  Future<void> deleteBusinessCard(String cardId) async {
    try {
      await _db
          .from('business_cards')
          .delete()
          .eq('id', cardId)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete business card: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 2: SCAN HISTORY
  // ════════════════════════════════════════════════════════════

  Future<List<ScanHistory>> fetchScanHistory() async {
    try {
      final response = await _db
          .from('scan_history')
          .select()
          .eq('user_id', _userId)
          .order('scanned_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((row) => ScanHistory.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch scan history: $e');
    }
  }

  Future<ScanHistory> saveScan(String scannedText) async {
    try {
      final response = await _db
          .from('scan_history')
          .insert({
            'user_id': _userId,
            'scanned_text': scannedText,
          })
          .select()
          .single();

      return ScanHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save scan: $e');
    }
  }

  Future<void> deleteScan(String scanId) async {
    try {
      await _db
          .from('scan_history')
          .delete()
          .eq('id', scanId)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete scan: $e');
    }
  }

  Future<void> clearScanHistory() async {
    try {
      await _db.from('scan_history').delete().eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to clear scan history: $e');
    }
  }

  Future<AdminDashboardData> fetchAdminDashboardData() async {
    try {
      final cards = await _db
          .from('business_cards')
          .select('id,user_id,name,email,created_at')
          .order('created_at', ascending: false);

      final recordings = await _db
          .from('recordings')
          .select('id,user_id,title,duration_ms,created_at')
          .order('created_at', ascending: false);

      final scans = await _db
          .from('scan_history')
          .select('id,user_id,scanned_text,scanned_at')
          .order('scanned_at', ascending: false);

      final cardRows = _asRows(cards);
      final recordingRows = _asRows(recordings);
      final scanRows = _asRows(scans);

      final userIds = <String>{
        ...cardRows.map((row) => row['user_id'] as String? ?? ''),
        ...recordingRows.map((row) => row['user_id'] as String? ?? ''),
        ...scanRows.map((row) => row['user_id'] as String? ?? ''),
      }..remove('');

      return AdminDashboardData(
        totalCards: cardRows.length,
        totalRecordings: recordingRows.length,
        totalScans: scanRows.length,
        totalKnownUsers: userIds.length,
        recentCards: cardRows.take(5).toList(),
        recentRecordings: recordingRows.take(5).toList(),
        recentScans: scanRows.take(5).toList(),
      );
    } catch (e) {
      throw Exception('Failed to fetch admin dashboard data: $e');
    }
  }

  List<Map<String, dynamic>> _asRows(dynamic response) {
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 3: AUDIO RECORDINGS (metadata)
  // ════════════════════════════════════════════════════════════

  Future<List<Recording>> fetchRecordings() async {
    try {
      final response = await _db
          .from('recordings')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Recording.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recordings: $e');
    }
  }

  Future<Recording> createRecording(Recording recording) async {
    try {
      final response = await _db
          .from('recordings')
          .insert({
            'user_id': _userId,
            ...recording.toJson(),
          })
          .select()
          .single();

      return Recording.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create recording: $e');
    }
  }

  Future<Recording> updateRecording(Recording recording) async {
    try {
      final response = await _db
          .from('recordings')
          .update({
            'title': recording.title,
            'notes': recording.notes,
          })
          .eq('id', recording.id)
          .eq('user_id', _userId)
          .select()
          .single();

      return Recording.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update recording: $e');
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      await _db
          .from('recordings')
          .delete()
          .eq('id', recordingId)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete recording: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 4: STORAGE (Audio Files)
  // ════════════════════════════════════════════════════════════

  // ── Upload audio file to Supabase Storage ─────────────────
  // Uses dart:io File to read bytes from the local path,
  // then uploads to the 'recordings' bucket.
  // Returns the storage path used as filePath in Recording.
  Future<String> uploadAudioFile({
    required String localFilePath,
    required String fileName,
  }) async {
    try {
      final storagePath = '$_userId/$fileName';
      final file = File(localFilePath); // dart:io File
      final bytes = await file.readAsBytes(); // Uint8List

      await _db.storage.from('recordings').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4', // MIME type for .m4a
              upsert: false,
            ),
          );

      return storagePath;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  // ── Get a signed URL to play an audio file ────────────────
  Future<String> getAudioUrl(String storagePath) async {
    try {
      return await _db.storage
          .from('recordings')
          .createSignedUrl(storagePath, 3600); // 1 hour expiry
    } catch (e) {
      throw Exception('Failed to get audio URL: $e');
    }
  }

  // ── Delete audio file from Storage ────────────────────────
  Future<void> deleteAudioFile(String storagePath) async {
    try {
      await _db.storage.from('recordings').remove([storagePath]);
    } catch (_) {
      // Silently ignore — file may already be deleted
    }
  }
}
