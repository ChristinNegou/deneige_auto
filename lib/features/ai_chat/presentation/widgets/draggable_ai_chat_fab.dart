import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// FAB déplaçable pour le chatbot IA utilisant Overlay
/// Apparaît au-dessus de tout le contenu
class DraggableAIChatFab extends StatefulWidget {
  final String screenId;

  const DraggableAIChatFab({
    super.key,
    this.screenId = 'default',
  });

  @override
  State<DraggableAIChatFab> createState() => _DraggableAIChatFabState();
}

class _DraggableAIChatFabState extends State<DraggableAIChatFab> {
  OverlayEntry? _overlayEntry;
  double? _posX;
  double? _posY;

  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPositionAndShowOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadPositionAndShowOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _posX = prefs.getDouble(_xKey);
      _posY = prefs.getDouble(_yKey);
    } catch (_) {}

    if (mounted) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _DraggableFabOverlay(
        initialX: _posX,
        initialY: _posY,
        screenId: widget.screenId,
        onPositionChanged: (x, y) {
          _posX = x;
          _posY = y;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _DraggableFabOverlay extends StatefulWidget {
  final double? initialX;
  final double? initialY;
  final String screenId;
  final Function(double, double) onPositionChanged;

  const _DraggableFabOverlay({
    this.initialX,
    this.initialY,
    required this.screenId,
    required this.onPositionChanged,
  });

  @override
  State<_DraggableFabOverlay> createState() => _DraggableFabOverlayState();
}

class _DraggableFabOverlayState extends State<_DraggableFabOverlay> {
  double? _posX;
  double? _posY;
  bool _isDragging = false;

  static const double _fabSize = 56;

  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    _posX = widget.initialX;
    _posY = widget.initialY;
  }

  Future<void> _savePosition() async {
    if (_posX == null || _posY == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xKey, _posX!);
      await prefs.setDouble(_yKey, _posY!);
      widget.onPositionChanged(_posX!, _posY!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    final topPadding = mediaQuery.padding.top;

    const minX = 10.0;
    final maxX = screenWidth - _fabSize - 10;
    final minY = topPadding + 10;
    final maxY = screenHeight - _fabSize - bottomPadding - 80;

    final currentX = _posX ?? (screenWidth - _fabSize - 20);
    final currentY = _posY ?? (screenHeight - _fabSize - bottomPadding - 120);

    final clampedX = currentX.clamp(minX, maxX);
    final clampedY = currentY.clamp(minY, maxY);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _posX = ((_posX ?? currentX) + details.delta.dx).clamp(minX, maxX);
            _posY = ((_posY ?? currentY) + details.delta.dy).clamp(minY, maxY);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          final centerX = screenWidth / 2;
          setState(() {
            if ((_posX ?? currentX) + _fabSize / 2 < centerX) {
              _posX = 20;
            } else {
              _posX = screenWidth - _fabSize - 20;
            }
          });
          _savePosition();
        },
        onTap: () {
          if (!_isDragging) {
            Navigator.pushNamed(context, AppRoutes.aiChat);
          }
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Material(
            elevation: _isDragging ? 12 : 6,
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.primary2,
            shadowColor: AppTheme.primary2.withValues(alpha: 0.4),
            child: Container(
              width: _fabSize,
              height: _fabSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget simple pour ajouter le FAB IA à n'importe quel écran
/// Place ce widget n'importe où dans l'arbre de widgets
class AIChatFabWrapper extends StatefulWidget {
  final Widget child;
  final String screenId;

  const AIChatFabWrapper({
    super.key,
    required this.child,
    this.screenId = 'default',
  });

  @override
  State<AIChatFabWrapper> createState() => _AIChatFabWrapperState();
}

class _AIChatFabWrapperState extends State<AIChatFabWrapper> {
  OverlayEntry? _overlayEntry;
  double? _posX;
  double? _posY;

  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPositionAndShowOverlay();
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  Future<void> _loadPositionAndShowOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _posX = prefs.getDouble(_xKey);
      _posY = prefs.getDouble(_yKey);
    } catch (_) {}

    if (mounted) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => _AIChatFabOverlayWidget(
        initialX: _posX,
        initialY: _posY,
        screenId: widget.screenId,
        onPositionChanged: (x, y) {
          _posX = x;
          _posY = y;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _AIChatFabOverlayWidget extends StatefulWidget {
  final double? initialX;
  final double? initialY;
  final String screenId;
  final Function(double, double) onPositionChanged;

  const _AIChatFabOverlayWidget({
    this.initialX,
    this.initialY,
    required this.screenId,
    required this.onPositionChanged,
  });

  @override
  State<_AIChatFabOverlayWidget> createState() =>
      _AIChatFabOverlayWidgetState();
}

class _AIChatFabOverlayWidgetState extends State<_AIChatFabOverlayWidget> {
  double? _posX;
  double? _posY;
  bool _isDragging = false;

  static const double _fabSize = 56;

  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    _posX = widget.initialX;
    _posY = widget.initialY;
  }

  Future<void> _savePosition() async {
    if (_posX == null || _posY == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xKey, _posX!);
      await prefs.setDouble(_yKey, _posY!);
      widget.onPositionChanged(_posX!, _posY!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    final topPadding = mediaQuery.padding.top;

    const minX = 10.0;
    final maxX = screenWidth - _fabSize - 10;
    final minY = topPadding + 10;
    final maxY = screenHeight - _fabSize - bottomPadding - 80;

    final currentX = _posX ?? (screenWidth - _fabSize - 20);
    final currentY = _posY ?? (screenHeight - _fabSize - bottomPadding - 120);

    final clampedX = currentX.clamp(minX, maxX);
    final clampedY = currentY.clamp(minY, maxY);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) {
            setState(() {
              _posX =
                  ((_posX ?? currentX) + details.delta.dx).clamp(minX, maxX);
              _posY =
                  ((_posY ?? currentY) + details.delta.dy).clamp(minY, maxY);
            });
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            final centerX = screenWidth / 2;
            setState(() {
              if ((_posX ?? currentX) + _fabSize / 2 < centerX) {
                _posX = 20;
              } else {
                _posX = screenWidth - _fabSize - 20;
              }
            });
            _savePosition();
          },
          onTap: () {
            if (!_isDragging) {
              Navigator.pushNamed(context, AppRoutes.aiChat);
            }
          },
          child: AnimatedScale(
            scale: _isDragging ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: _fabSize,
              height: _fabSize,
              decoration: BoxDecoration(
                color: AppTheme.primary2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary2.withValues(alpha: 0.4),
                    blurRadius: _isDragging ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
