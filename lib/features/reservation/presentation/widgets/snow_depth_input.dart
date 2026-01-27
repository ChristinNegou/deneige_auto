import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class SnowDepthInput extends StatefulWidget {
  final int? initialValue;
  final ValueChanged<int?> onChanged;

  const SnowDepthInput({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SnowDepthInput> createState() => _SnowDepthInputState();
}

class _SnowDepthInputState extends State<SnowDepthInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.ac_unit,
                color: AppTheme.info,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.snow_estimatedDepth,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.snow_optionalHelper,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.info.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final current = int.tryParse(_controller.text) ?? 0;
                  if (current > 0) {
                    final newValue = current - 5;
                    _controller.text = newValue.toString();
                    widget.onChanged(newValue);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.primary,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppTheme.textTertiary),
                    suffix: Text(
                      'cm',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    widget.onChanged(intValue);
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  final current = int.tryParse(_controller.text) ?? 0;
                  if (current < 100) {
                    final newValue = current + 5;
                    _controller.text = newValue.toString();
                    widget.onChanged(newValue);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primary,
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceContainer,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.2),
              valueIndicatorColor: AppTheme.primary,
              valueIndicatorTextStyle: TextStyle(
                color: AppTheme.background,
              ),
            ),
            child: Slider(
              value: (int.tryParse(_controller.text) ?? 0).toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_controller.text} cm',
              onChanged: (value) {
                final intValue = value.round();
                _controller.text = intValue.toString();
                widget.onChanged(intValue);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 cm',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '100 cm',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
