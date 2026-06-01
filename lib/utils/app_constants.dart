import 'package:flutter/material.dart';

class Tables {
  static const String businessCards = 'business_cards';
  static const String scanHistory = 'scan_history';
  static const String recordings = 'recordings';
}

class Buckets {
  static const String recordings = 'recordings';
}

class ModuleColors {
  static const Color qrCard = Color(0xFF3B82F6);
  static const Color qrCardLight = Color(0xFFEFF6FF);

  static const Color converter = Color(0xFF10B981);
  static const Color converterLight = Color(0xFFECFDF5);

  static const Color recorder = Color(0xFFF59E0B);
  static const Color recorderLight = Color(0xFFFFFBEB);
}

class AppStrings {
  static const String appName = 'Personal Utility';
  static const String appTagline = 'Your tools, all in one place';

  static const String qrCardModule = 'QR Business Card';
  static const String converterModule = 'Unit Converter';
  static const String recorderModule = 'Audio Recorder';

  static const String qrCardDesc = 'Create digital cards & generate QR codes';
  static const String converterDesc = 'Convert length, weight & temperature';
  static const String recorderDesc = 'Record, save & play audio with notes';
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
}
