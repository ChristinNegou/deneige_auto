import 'package:flutter/material.dart';

class SnowDepthInput extends StatefulWidget {
  final int? initialValue;
  final ValueChanged<int?> onChanged;

  const SnowDepthInput({
    Key? key,
    this.initialValue,
    required this.onChanged,
  }) : super(key: key);

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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.ac_unit,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Profondeur de neige estimée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Optionnel - Aide à estimer le temps requis',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[700],
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
                color: Theme.of(context).primaryColor,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffix: Text(
                      'cm',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
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
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
          Slider(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 cm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '100 cm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
