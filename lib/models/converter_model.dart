class ConversionUnit {
  final String name;
  final String symbol;

  final double Function(double) toBase;

  final double Function(double) fromBase;

  const ConversionUnit({
    required this.name,
    required this.symbol,
    required this.toBase,
    required this.fromBase,
  });

  @override
  String toString() => '$name ($symbol)';
}

class ConversionCategory {
  final String name;
  final String icon;
  final String baseUnitSymbol;
  final List<ConversionUnit> units;

  const ConversionCategory({
    required this.name,
    required this.icon,
    required this.baseUnitSymbol,
    required this.units,
  });

  @override
  String toString() => 'ConversionCategory($name, ${units.length} units)';
}

class ConverterModel {
  ConverterModel._();

  static final List<ConversionCategory> categories = [
    _buildLengthCategory(),
    _buildTemperatureCategory(),
    _buildWeightCategory(),
  ];

  static double convert({
    required double value,
    required ConversionUnit from,
    required ConversionUnit to,
  }) {
    final double baseValue = from.toBase(value);
    return to.fromBase(baseValue);
  }

  static String formatResult(double value) {
    if (value.isNaN || value.isInfinite) return 'Invalid';

    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static ConversionCategory _buildLengthCategory() {
    return ConversionCategory(
      name: 'Length',
      icon: '📏',
      baseUnitSymbol: 'm',
      units: [
        ConversionUnit(
          name: 'Meters',
          symbol: 'm',
          toBase: (v) => v,
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name: 'Kilometers',
          symbol: 'km',
          toBase: (v) => v * 1000,
          fromBase: (v) => v / 1000,
        ),
        ConversionUnit(
          name: 'Centimeters',
          symbol: 'cm',
          toBase: (v) => v / 100,
          fromBase: (v) => v * 100,
        ),
        ConversionUnit(
          name: 'Millimeters',
          symbol: 'mm',
          toBase: (v) => v / 1000,
          fromBase: (v) => v * 1000,
        ),
        ConversionUnit(
          name: 'Feet',
          symbol: 'ft',
          toBase: (v) => v * 0.3048,
          fromBase: (v) => v / 0.3048,
        ),
        ConversionUnit(
          name: 'Inches',
          symbol: 'in',
          toBase: (v) => v * 0.0254,
          fromBase: (v) => v / 0.0254,
        ),
        ConversionUnit(
          name: 'Yards',
          symbol: 'yd',
          toBase: (v) => v * 0.9144,
          fromBase: (v) => v / 0.9144,
        ),
        ConversionUnit(
          name: 'Miles',
          symbol: 'mi',
          toBase: (v) => v * 1609.344,
          fromBase: (v) => v / 1609.344,
        ),
      ],
    );
  }

  static ConversionCategory _buildTemperatureCategory() {
    return ConversionCategory(
      name: 'Temperature',
      icon: '🌡️',
      baseUnitSymbol: '°C',
      units: [
        ConversionUnit(
          name: 'Celsius',
          symbol: '°C',
          toBase: (v) => v,
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name: 'Fahrenheit',
          symbol: '°F',
          toBase: (v) => (v - 32) * 5 / 9,
          fromBase: (v) => (v * 9 / 5) + 32,
        ),
        ConversionUnit(
          name: 'Kelvin',
          symbol: 'K',
          toBase: (v) => v - 273.15,
          fromBase: (v) => v + 273.15,
        ),
      ],
    );
  }

  static ConversionCategory _buildWeightCategory() {
    return ConversionCategory(
      name: 'Weight',
      icon: '⚖️',
      baseUnitSymbol: 'kg',
      units: [
        ConversionUnit(
          name: 'Kilograms',
          symbol: 'kg',
          toBase: (v) => v,
          fromBase: (v) => v,
        ),
        ConversionUnit(
          name: 'Grams',
          symbol: 'g',
          toBase: (v) => v / 1000,
          fromBase: (v) => v * 1000,
        ),
        ConversionUnit(
          name: 'Milligrams',
          symbol: 'mg',
          toBase: (v) => v / 1000000,
          fromBase: (v) => v * 1000000,
        ),
        ConversionUnit(
          name: 'Pounds',
          symbol: 'lb',
          toBase: (v) => v * 0.453592,
          fromBase: (v) => v / 0.453592,
        ),
        ConversionUnit(
          name: 'Ounces',
          symbol: 'oz',
          toBase: (v) => v * 0.0283495,
          fromBase: (v) => v / 0.0283495,
        ),
        ConversionUnit(
          name: 'Metric Tons',
          symbol: 't',
          toBase: (v) => v * 1000,
          fromBase: (v) => v / 1000,
        ),
        ConversionUnit(
          name: 'Stone',
          symbol: 'st',
          toBase: (v) => v * 6.35029,
          fromBase: (v) => v / 6.35029,
        ),
      ],
    );
  }
}
