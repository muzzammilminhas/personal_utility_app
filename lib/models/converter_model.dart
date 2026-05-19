// ============================================================
//  lib/models/converter_model.dart
//  Data + Logic Classes — Unit Converter Module
// ============================================================
//
//  This file contains THREE classes:
//
//  1. ConversionUnit      → a single unit (e.g. "Kilometers")
//  2. ConversionCategory  → a group of units (e.g. "Length")
//  3. ConverterModel      → static factory that builds all
//                           categories and performs conversion
//
//  WHY NO fromJson() / toJson() HERE?
//  ────────────────────────────────────────────────────────
//  The Unit Converter does NOT store data in Supabase.
//  All unit definitions are hardcoded in Dart because they
//  are fixed mathematical constants that never change.
//  There is nothing to read from or write to a database.
//
//  This file is PURE DART — no Flutter, no Supabase imports.
//  That makes it easy to understand and test independently.
//
//  CONVERSION STRATEGY — BASE UNIT METHOD:
//  ────────────────────────────────────────────────────────
//  Instead of writing a conversion formula for every possible
//  pair (N² formulas), each unit only needs TWO functions:
//
//    toBase(value)   → converts THIS unit → the base unit
//    fromBase(value) → converts the base unit → THIS unit
//
//  To convert from unit A → unit B:
//    Step 1:  base = A.toBase(inputValue)
//    Step 2:  result = B.fromBase(base)
//
//  Example (Length, base = Meters):
//    Feet → Inches:
//    Step 1: 1 ft → 0.3048 m    (toBase: v * 0.3048)
//    Step 2: 0.3048 m → 12 in   (fromBase: v / 0.0254)
//    Result: 12 inches  ✓
//
// ============================================================


// ── CLASS 1: ConversionUnit ───────────────────────────────
//
//  Represents ONE selectable unit in a dropdown.
//
//  ATTRIBUTES:
//  • name     → full display name   e.g. "Kilometers"
//  • symbol   → short symbol        e.g. "km"
//  • toBase   → function: converts this unit → base unit
//  • fromBase → function: converts base unit → this unit
//
//  Both toBase and fromBase are of type:
//    double Function(double)
//  meaning: a function that takes one double and returns one double.
// ─────────────────────────────────────────────────────────

class ConversionUnit {
  // ── Attributes ────────────────────────────────────────────

  final String name;    // Full name shown in UI: "Kilometers", "Fahrenheit"
  final String symbol;  // Short label shown in badge: "km", "°F", "lb"

  // Function that converts a value FROM this unit TO the base unit
  // Type: double Function(double value)
  final double Function(double) toBase;

  // Function that converts a value FROM the base unit TO this unit
  // Type: double Function(double baseValue)
  final double Function(double) fromBase;

  // ── Constructor ───────────────────────────────────────────
  //
  //  'const' constructor is used here because all values are
  //  known at compile time. This makes the list of units
  //  more memory-efficient.

  const ConversionUnit({
    required this.name,
    required this.symbol,
    required this.toBase,
    required this.fromBase,
  });

  // ── toString() ────────────────────────────────────────────

  @override
  String toString() => '$name ($symbol)';
}


// ── CLASS 2: ConversionCategory ──────────────────────────
//
//  Represents ONE tab in the converter UI.
//  Groups related ConversionUnit objects together.
//
//  ATTRIBUTES:
//  • name           → "Length", "Temperature", "Weight"
//  • icon           → emoji for visual identity
//  • baseUnitSymbol → which unit is the "base" (reference)
//  • units          → list of all available units in this group
// ─────────────────────────────────────────────────────────

class ConversionCategory {
  // ── Attributes ────────────────────────────────────────────

  final String name;            // Display name for the tab
  final String icon;            // Emoji: "📏", "🌡️", "⚖️"
  final String baseUnitSymbol;  // Symbol of the base unit: "m", "°C", "kg"
  final List<ConversionUnit> units; // All units that belong to this category

  // ── Constructor ───────────────────────────────────────────

  const ConversionCategory({
    required this.name,
    required this.icon,
    required this.baseUnitSymbol,
    required this.units,
  });

  // ── toString() ────────────────────────────────────────────

  @override
  String toString() => 'ConversionCategory($name, ${units.length} units)';
}


// ── CLASS 3: ConverterModel ───────────────────────────────
//
//  A static utility class — you never create an instance of it.
//  It provides:
//    • categories → the full list of all 3 categories
//    • convert()  → performs the two-step base-unit conversion
//    • formatResult() → trims trailing zeros from the result
//
//  The private constructor ConverterModel._() prevents anyone
//  from accidentally writing:  var m = ConverterModel();
// ─────────────────────────────────────────────────────────

class ConverterModel {
  // ── Private constructor: prevents instantiation ───────────
  ConverterModel._();

  // ── ATTRIBUTE: All three conversion categories ────────────
  //
  //  This is a static field — it belongs to the CLASS,
  //  not to any instance. Access it as: ConverterModel.categories
  //
  //  It is initialized by calling three private factory methods
  //  defined below.

  static final List<ConversionCategory> categories = [
    _buildLengthCategory(),
    _buildTemperatureCategory(),
    _buildWeightCategory(),
  ];

  // ── METHOD: convert() ─────────────────────────────────────
  //
  //  The core conversion logic using the two-step base method.
  //
  //  PARAMETERS:
  //  • value → the number the user typed
  //  • from  → the ConversionUnit selected in the "from" dropdown
  //  • to    → the ConversionUnit selected in the "to" dropdown
  //
  //  RETURNS: the converted double value
  //
  //  EXAMPLE:
  //    convert(value: 100, from: feet, to: meters)
  //    Step 1: 100 * 0.3048 = 30.48 meters  (feet.toBase)
  //    Step 2: 30.48 * 1.0 = 30.48          (meters.fromBase — IS the base)
  //    Returns: 30.48

  static double convert({
    required double value,
    required ConversionUnit from,
    required ConversionUnit to,
  }) {
    final double baseValue = from.toBase(value);  // Step 1: → base unit
    return to.fromBase(baseValue);                 // Step 2: base unit → target
  }

  // ── METHOD: formatResult() ────────────────────────────────
  //
  //  Formats a double into a clean string without unnecessary
  //  trailing zeros. Max 4 decimal places.
  //
  //  EXAMPLES:
  //    1.00000  → "1"
  //    2.50000  → "2.5"
  //    1.23456  → "1.2346"
  //    30.48000 → "30.48"
  //
  //  toStringAsFixed(4) → "30.4800"
  //  replaceAll(RegExp(r'0+$'), '') → remove trailing 0s → "30.48"
  //  replaceAll(RegExp(r'\.$'), '')  → remove trailing dot if any → "30"

  static String formatResult(double value) {
    if (value.isNaN || value.isInfinite) return 'Invalid';

    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')   // remove trailing zeros
        .replaceAll(RegExp(r'\.$'), '');  // remove trailing dot
  }


  // ════════════════════════════════════════════════════════
  //  PRIVATE FACTORY METHODS — Build each category's units
  //  These are static private methods (start with _) so they
  //  can only be called from within this class.
  // ════════════════════════════════════════════════════════

  // ── Category 1: LENGTH (base unit = Meters) ──────────────
  //
  //  Conversion factors:
  //  • 1 km   = 1,000 m
  //  • 1 cm   = 0.01 m
  //  • 1 mm   = 0.001 m
  //  • 1 ft   = 0.3048 m
  //  • 1 in   = 0.0254 m
  //  • 1 yd   = 0.9144 m
  //  • 1 mi   = 1,609.344 m

  static ConversionCategory _buildLengthCategory() {
    return ConversionCategory(
      name:           'Length',
      icon:           '📏',
      baseUnitSymbol: 'm',
      units: [
        ConversionUnit(
          name:     'Meters',
          symbol:   'm',
          toBase:   (v) => v,          // meters IS the base — no conversion
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name:     'Kilometers',
          symbol:   'km',
          toBase:   (v) => v * 1000,   // 1 km = 1000 m
          fromBase: (v) => v / 1000,
        ),
        ConversionUnit(
          name:     'Centimeters',
          symbol:   'cm',
          toBase:   (v) => v / 100,    // 100 cm = 1 m
          fromBase: (v) => v * 100,
        ),
        ConversionUnit(
          name:     'Millimeters',
          symbol:   'mm',
          toBase:   (v) => v / 1000,
          fromBase: (v) => v * 1000,
        ),
        ConversionUnit(
          name:     'Feet',
          symbol:   'ft',
          toBase:   (v) => v * 0.3048,
          fromBase: (v) => v / 0.3048,
        ),
        ConversionUnit(
          name:     'Inches',
          symbol:   'in',
          toBase:   (v) => v * 0.0254,
          fromBase: (v) => v / 0.0254,
        ),
        ConversionUnit(
          name:     'Yards',
          symbol:   'yd',
          toBase:   (v) => v * 0.9144,
          fromBase: (v) => v / 0.9144,
        ),
        ConversionUnit(
          name:     'Miles',
          symbol:   'mi',
          toBase:   (v) => v * 1609.344,
          fromBase: (v) => v / 1609.344,
        ),
      ],
    );
  }

  // ── Category 2: TEMPERATURE (base unit = Celsius) ─────────
  //
  //  Temperature uses OFFSET formulas, NOT simple multipliers.
  //  This is why we store functions instead of a single factor.
  //
  //  Formulas:
  //  • Celsius → Fahrenheit: (C × 9/5) + 32
  //  • Fahrenheit → Celsius: (F − 32) × 5/9
  //  • Celsius → Kelvin:     C + 273.15
  //  • Kelvin  → Celsius:    K − 273.15

  static ConversionCategory _buildTemperatureCategory() {
    return ConversionCategory(
      name:           'Temperature',
      icon:           '🌡️',
      baseUnitSymbol: '°C',
      units: [
        ConversionUnit(
          name:     'Celsius',
          symbol:   '°C',
          toBase:   (v) => v,                    // Celsius IS the base
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name:     'Fahrenheit',
          symbol:   '°F',
          toBase:   (v) => (v - 32) * 5 / 9,    // °F → °C
          fromBase: (v) => (v * 9 / 5) + 32,    // °C → °F
        ),
        ConversionUnit(
          name:     'Kelvin',
          symbol:   'K',
          toBase:   (v) => v - 273.15,           // K → °C
          fromBase: (v) => v + 273.15,           // °C → K
        ),
      ],
    );
  }

  // ── Category 3: WEIGHT / MASS (base unit = Kilograms) ─────
  //
  //  Conversion factors:
  //  • 1 g    = 0.001 kg
  //  • 1 mg   = 0.000001 kg
  //  • 1 lb   = 0.453592 kg
  //  • 1 oz   = 0.0283495 kg
  //  • 1 t    = 1,000 kg
  //  • 1 st   = 6.35029 kg  (stone, used in UK)

  static ConversionCategory _buildWeightCategory() {
    return ConversionCategory(
      name:           'Weight',
      icon:           '⚖️',
      baseUnitSymbol: 'kg',
      units: [
        ConversionUnit(
          name:     'Kilograms',
          symbol:   'kg',
          toBase:   (v) => v,
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name:     'Grams',
          symbol:   'g',
          toBase:   (v) => v / 1000,
          fromBase: (v) => v * 1000,
        ),
        ConversionUnit(
          name:     'Milligrams',
          symbol:   'mg',
          toBase:   (v) => v / 1000000,
          fromBase: (v) => v * 1000000,
        ),
        ConversionUnit(
          name:     'Pounds',
          symbol:   'lb',
          toBase:   (v) => v * 0.453592,
          fromBase: (v) => v / 0.453592,
        ),
        ConversionUnit(
          name:     'Ounces',
          symbol:   'oz',
          toBase:   (v) => v * 0.0283495,
          fromBase: (v) => v / 0.0283495,
        ),
        ConversionUnit(
          name:     'Metric Tons',
          symbol:   't',
          toBase:   (v) => v * 1000,
          fromBase: (v) => v / 1000,
        ),
        ConversionUnit(
          name:     'Stone',
          symbol:   'st',
          toBase:   (v) => v * 6.35029,
          fromBase: (v) => v / 6.35029,
        ),
      ],
    );
  }
}