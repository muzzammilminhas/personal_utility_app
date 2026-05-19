// ============================================================
//  utils/app_constants.dart  –  Centralized Constants
// ============================================================
//
//  Keeping all magic strings, colors, and route names here
//  means you only have to change them in ONE place.
//  This is called the DRY principle (Don't Repeat Yourself).
//
// ============================================================

import 'package:flutter/material.dart';

// ── Supabase Table Names ────────────────────────────────────
// If you rename a table, update it here only
class Tables {
  static const String businessCards = 'business_cards';
  static const String scanHistory = 'scan_history';
  static const String recordings = 'recordings';
}

// ── Storage Bucket Names ────────────────────────────────────
class Buckets {
  static const String recordings = 'recordings';
}

// ── Module Colors ───────────────────────────────────────────
// Each module has its own accent color for visual identity
class ModuleColors {
  // QR Business Card — blue/indigo
  static const Color qrCard = Color(0xFF3B82F6);
  static const Color qrCardLight = Color(0xFFEFF6FF);

  // Unit Converter — green/teal
  static const Color converter = Color(0xFF10B981);
  static const Color converterLight = Color(0xFFECFDF5);

  // Audio Recorder — orange/amber
  static const Color recorder = Color(0xFFF59E0B);
  static const Color recorderLight = Color(0xFFFFFBEB);
}

// ── App Text Strings ────────────────────────────────────────
// Keeps UI copy in one place for easy editing
class AppStrings {
  static const String appName = 'Personal Utility';
  static const String appTagline = 'Your tools, all in one place';

  // Module names
  static const String qrCardModule = 'QR Business Card';
  static const String converterModule = 'Unit Converter';
  static const String recorderModule = 'Audio Recorder';

  // Module descriptions shown on home cards
  static const String qrCardDesc =
      'Create digital cards & generate QR codes';
  static const String converterDesc =
      'Convert length, weight & temperature';
  static const String recorderDesc =
      'Record, save & play audio with notes';
}

// ── Spacing Constants ───────────────────────────────────────
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ── Border Radius Constants ─────────────────────────────────
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
}
