import 'package:flutter/material.dart';

import '../../models/converter_model.dart';
import '../../utils/app_constants.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: ConverterModel.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
        backgroundColor: ModuleColors.converterLight,
        foregroundColor: ModuleColors.converter,
        bottom: TabBar(
          controller: _tabController,
          labelColor: ModuleColors.converter,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: ModuleColors.converter,
          indicatorWeight: 3,
          tabs: ConverterModel.categories
              .map(
                (cat) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ConverterModel.categories
            .map((cat) => _ConverterTab(category: cat))
            .toList(),
      ),
    );
  }
}

class _ConverterTab extends StatefulWidget {
  final ConversionCategory category;

  const _ConverterTab({required this.category});

  @override
  State<_ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<_ConverterTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TextEditingController _inputController;
  late ConversionUnit _fromUnit;
  late ConversionUnit _toUnit;
  String _result = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();

    _fromUnit = widget.category.units.first;
    _toUnit = widget.category.units.length > 1
        ? widget.category.units[1]
        : widget.category.units.first;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _compute() {
    final inputText = _inputController.text.trim();

    if (inputText.isEmpty) {
      setState(() {
        _result = '';
        _hasError = false;
      });
      return;
    }

    final inputValue = double.tryParse(inputText);
    if (inputValue == null) {
      setState(() {
        _result = 'Invalid number';
        _hasError = true;
      });
      return;
    }

    if (_fromUnit.symbol == _toUnit.symbol) {
      setState(() {
        _result = ConverterModel.formatResult(inputValue);
        _hasError = false;
      });
      return;
    }

    final converted = ConverterModel.convert(
      value: inputValue,
      from: _fromUnit,
      to: _toUnit,
    );

    setState(() {
      _result = ConverterModel.formatResult(converted);
      _hasError = false;
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });

    _compute();
  }

  void _clear() {
    _inputController.clear();
    setState(() {
      _result = '';
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _buildCategoryHeader(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildInputSection(theme),
          const SizedBox(height: AppSpacing.md),
          _buildSwapRow(theme),
          const SizedBox(height: AppSpacing.md),
          _buildResultSection(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildReferenceTable(theme),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: ModuleColors.converterLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Text(widget.category.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ModuleColors.converter,
                ),
              ),
              Text(
                '${widget.category.units.length} units available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ModuleColors.converter.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _inputController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              textInputAction: TextInputAction.done,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.outlineVariant,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: _hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      const BorderSide(color: ModuleColors.converter, width: 2),
                ),
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clear,
                      )
                    : null,
              ),
              onChanged: (_) => _compute(),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildUnitDropdown(
              label: 'Convert from',
              selected: _fromUnit,
              onChanged: (unit) {
                if (unit != null) {
                  setState(() => _fromUnit = unit);
                  _compute();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapRow(ThemeData theme) {
    return Center(
      child: GestureDetector(
        onTap: _swapUnits,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ModuleColors.converter,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ModuleColors.converter.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_vert_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(ThemeData theme) {
    return Card(
      color: _hasError
          ? theme.colorScheme.errorContainer
          : _result.isNotEmpty
              ? ModuleColors.converterLight
              : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _result.isEmpty
                        ? '—'
                        : _hasError
                            ? _result
                            : _result,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _hasError
                          ? theme.colorScheme.error
                          : _result.isEmpty
                              ? theme.colorScheme.outlineVariant
                              : ModuleColors.converter,
                    ),
                  ),
                ),
                if (_result.isNotEmpty && !_hasError)
                  Text(
                    _toUnit.symbol,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: ModuleColors.converter.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildUnitDropdown(
              label: 'Convert to',
              selected: _toUnit,
              onChanged: (unit) {
                if (unit != null) {
                  setState(() => _toUnit = unit);
                  _compute();
                }
              },
            ),
            if (_result.isNotEmpty && !_hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_inputController.text} ${_fromUnit.symbol} = $_result ${_toUnit.symbol}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ModuleColors.converter.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitDropdown({
    required String label,
    required ConversionUnit selected,
    required void Function(ConversionUnit?) onChanged,
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<ConversionUnit>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: ModuleColors.converter, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      onChanged: onChanged,
      items: widget.category.units.map((unit) {
        return DropdownMenuItem<ConversionUnit>(
          value: unit,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ModuleColors.converterLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit.symbol,
                  style: const TextStyle(
                    color: ModuleColors.converter,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(unit.name, style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReferenceTable(ThemeData theme) {
    final refs = _getQuickReferences();
    if (refs.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: ModuleColors.converter, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Quick Reference',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ModuleColors.converter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            ...refs.map((ref) => _buildRefRow(ref, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildRefRow(_QuickRef ref, ThemeData theme) {
    final fromUnit = widget.category.units.firstWhere(
        (u) => u.symbol == ref.fromSymbol,
        orElse: () => widget.category.units.first);
    final toUnit = widget.category.units.firstWhere(
        (u) => u.symbol == ref.toSymbol,
        orElse: () => widget.category.units.last);

    final result =
        ConverterModel.convert(value: ref.value, from: fromUnit, to: toUnit);
    final resultStr = ConverterModel.formatResult(result);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '${ref.value % 1 == 0 ? ref.value.toInt() : ref.value} ${ref.fromSymbol}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward,
              size: 14, color: ModuleColors.converter),
          const Spacer(),
          Text(
            '$resultStr ${ref.toSymbol}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ModuleColors.converter,
            ),
          ),
        ],
      ),
    );
  }

  List<_QuickRef> _getQuickReferences() {
    switch (widget.category.name) {
      case 'Length':
        return [
          _QuickRef(1, 'ft', 'm'),
          _QuickRef(1, 'mi', 'km'),
          _QuickRef(1, 'in', 'cm'),
          _QuickRef(1, 'km', 'mi'),
          _QuickRef(100, 'm', 'ft'),
        ];
      case 'Temperature':
        return [
          _QuickRef(0, '°C', '°F'),
          _QuickRef(100, '°C', '°F'),
          _QuickRef(32, '°F', '°C'),
          _QuickRef(212, '°F', '°C'),
          _QuickRef(0, '°C', 'K'),
        ];
      case 'Weight':
        return [
          _QuickRef(1, 'kg', 'lb'),
          _QuickRef(1, 'lb', 'kg'),
          _QuickRef(1, 'kg', 'oz'),
          _QuickRef(1, 'st', 'kg'),
          _QuickRef(1, 't', 'kg'),
        ];
      default:
        return [];
    }
  }
}

class _QuickRef {
  final double value;
  final String fromSymbol;
  final String toSymbol;

  const _QuickRef(this.value, this.fromSymbol, this.toSymbol);
}
