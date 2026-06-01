import 'package:flutter/material.dart';

import '../models/business_card.dart';
import '../models/scan_history.dart';
import '../services/database_service.dart';

class BusinessCardProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<BusinessCard> _cards = [];
  List<ScanHistory> _scanHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BusinessCard> get cards => _cards;
  List<ScanHistory> get scanHistory => _scanHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<bool> addCard(BusinessCard card) async {
    _setLoading(true);
    try {
      final newCard = await _db.createBusinessCard(card);

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

  Future<bool> updateCard(BusinessCard card) async {
    _setLoading(true);
    try {
      final updated = await _db.updateBusinessCard(card);

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

  Future<bool> deleteCard(String cardId) async {
    try {
      await _db.deleteBusinessCard(cardId);

      _cards.removeWhere((c) => c.id == cardId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
