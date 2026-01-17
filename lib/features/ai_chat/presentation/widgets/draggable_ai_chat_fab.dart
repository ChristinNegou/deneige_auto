import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// FAB déplaçable pour le chatbot IA
/// Utilise un Overlay pour être positionné au-dessus de tout
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
  // Position du FAB
  Offset _position = Offset.zero;
  bool _isPositionLoaded = false;

  // Taille du FAB
  static const double _fabSize = 56;

  // Clés pour SharedPreferences
  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_xKey);
      final y = prefs.getDouble(_yKey);
      if (x != null && y != null && mounted) {
        setState(() {
          _position = Offset(x, y);
          _isPositionLoaded = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xKey, _position.dx);
      await prefs.setDouble(_yKey, _position.dy);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Position par défaut en bas à droite
    if (!_isPositionLoaded) {
      _position = Offset(
        size.width - _fabSize - 20,
        size.height - _fabSize - padding.bottom - 100,
      );
    }

    // Assurer que la position est dans les limites
    final minX = 10.0;
    final maxX = size.width - _fabSize - 10;
    final minY = padding.top + 10;
    final maxY = size.height - _fabSize - padding.bottom - 10;

    final clampedX = _position.dx.clamp(minX, maxX);
    final clampedY = _position.dy.clamp(minY, maxY);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(minX, maxX),
              (_position.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onPanEnd: (_) {
          // Snap au bord le plus proche
          final centerX = size.width / 2;
          setState(() {
            if (_position.dx + _fabSize / 2 < centerX) {
              _position = Offset(20, _position.dy);
            } else {
              _position = Offset(size.width - _fabSize - 20, _position.dy);
            }
          });
          _savePosition();
        },
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.primary2,
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
    );
  }
}

/// Widget simple pour ajouter le FAB IA à n'importe quel écran
/// Wrap ton Scaffold body avec ce widget
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
  Offset _position = Offset.zero;
  bool _initialized = false;
  bool _isDragging = false;

  static const double _fabSize = 56;

  String get _xKey => 'ai_fab_x_${widget.screenId}';
  String get _yKey => 'ai_fab_y_${widget.screenId}';

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_xKey);
      final y = prefs.getDouble(_yKey);
      if (x != null && y != null && mounted) {
        setState(() {
          _position = Offset(x, y);
          _initialized = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xKey, _position.dx);
      await prefs.setDouble(_yKey, _position.dy);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Initialiser la position par défaut
        if (!_initialized) {
          _position = Offset(
            size.width - _fabSize - 20,
            size.height - _fabSize - 100,
          );
          _initialized = true;
        }

        // Limites
        final minX = 10.0;
        final maxX = size.width - _fabSize - 10;
        final minY = 10.0;
        final maxY = size.height - _fabSize - 10;

        final clampedX = _position.dx.clamp(minX, maxX);
        final clampedY = _position.dy.clamp(minY, maxY);

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned(
              left: clampedX,
              top: clampedY,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _position = Offset(
                      (_position.dx + details.delta.dx).clamp(minX, maxX),
                      (_position.dy + details.delta.dy).clamp(minY, maxY),
                    );
                  });
                },
                onPanEnd: (_) {
                  setState(() => _isDragging = false);
                  // Snap au bord
                  final centerX = size.width / 2;
                  setState(() {
                    if (_position.dx + _fabSize / 2 < centerX) {
                      _position = Offset(20, _position.dy);
                    } else {
                      _position =
                          Offset(size.width - _fabSize - 20, _position.dy);
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
            ),
          ],
        );
      },
    );
  }
}
