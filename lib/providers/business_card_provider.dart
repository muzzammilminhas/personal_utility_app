// ============================================================
//  providers/business_card_provider.dart
// ============================================================
//
//  Manages the STATE of the Business Card module:
//  • Holds the list of cards in memory
//  • Calls DatabaseService for all CRUD operations
//  • Notifies UI widgets when data changes
//
//  Pattern: Provider calls Service → updates local list → UI rebuilds
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/business_card.dart';
import '../models/scan_history.dart';
import '../services/database_service.dart';

class BusinessCardProvider extends ChangeNotifier {
  // ── Dependencies ───────────────────────────────────────────
  final DatabaseService _db = DatabaseService();

  // ── State ──────────────────────────────────────────────────
  List<BusinessCard> _cards = [];
  List<ScanHistory> _scanHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters (read-only access) ────────────────────────────
  List<BusinessCard> get cards => _cards;
  List<ScanHistory> get scanHistory => _scanHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── LOAD: fetch all cards from Supabase ───────────────────
  Future<void> loadCards() async {
    _setLoading(true);
    try {
      _cards = await _db.fetchBusinessCards();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── LOAD: fetch scan history ──────────────────────────────
  Future<void> loadScanHistory() async {
    _setLoading(true);
    try {
      _scanHistory = await _db.fetchScanHistory();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── CREATE: add a new card ─────────────────────────────────
  Future<bool> addCard(BusinessCard card) async {
    _setLoading(true);
    try {
      final newCard = await _db.createBusinessCard(card);
      // Add to front of list (newest first)
      _cards.insert(0, newCard);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── UPDATE: edit an existing card ─────────────────────────
  Future<bool> updateCard(BusinessCard card) async {
    _setLoading(true);
    try {
      final updated = await _db.updateBusinessCard(card);
      // Replace the old card in the list with the updated one
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = updated;
      }
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── DELETE: remove a card ─────────────────────────────────
  Future<bool> deleteCard(String cardId) async {
    try {
      await _db.deleteBusinessCard(cardId);
      // Remove from local list immediately (optimistic update)
      _cards.removeWhere((c) => c.id == cardId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── SAVE SCAN: store a QR scan result ─────────────────────
  Future<void> saveScan(String scannedText) async {
    try {
      final scan = await _db.saveScan(scannedText);
      _scanHistory.insert(0, scan);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ── DELETE SCAN: remove one scan entry ────────────────────
  Future<void> deleteScan(String scanId) async {
    try {
      await _db.deleteScan(scanId);
      _scanHistory.removeWhere((s) => s.id == scanId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ── CLEAR HISTORY: wipe all scan entries ──────────────────
  Future<void> clearScanHistory() async {
    try {
      await _db.clearScanHistory();
      _scanHistory.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
