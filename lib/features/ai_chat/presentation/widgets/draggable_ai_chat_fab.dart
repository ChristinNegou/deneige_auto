import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// FAB déplaçable pour le chatbot IA
/// Peut être glissé n'importe où sur l'écran et mémorise sa position
class DraggableAIChatFab extends StatefulWidget {
  final double bottomNavHeight;

  const DraggableAIChatFab({
    super.key,
    this.bottomNavHeight = 80,
  });

  @override
  State<DraggableAIChatFab> createState() => _DraggableAIChatFabState();
}

class _DraggableAIChatFabState extends State<DraggableAIChatFab>
    with SingleTickerProviderStateMixin {
  // Position du FAB
  double _xPosition = 0;
  double _yPosition = 0;
  bool _isInitialized = false;
  bool _isDragging = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Clés pour SharedPreferences
  static const String _xPositionKey = 'ai_chat_fab_x';
  static const String _yPositionKey = 'ai_chat_fab_y';

  // Taille du FAB
  static const double _fabSize = 56;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble(_xPositionKey);
      final savedY = prefs.getDouble(_yPositionKey);

      if (savedX != null && savedY != null) {
        setState(() {
          _xPosition = savedX;
          _yPosition = savedY;
          _isInitialized = true;
        });
      } else {
        // Position par défaut (en bas à droite)
        _setDefaultPosition();
      }
    } catch (e) {
      _setDefaultPosition();
    }
  }

  void _setDefaultPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        setState(() {
          _xPosition = screenSize.width - _fabSize - 16;
          _yPosition =
              screenSize.height - _fabSize - widget.bottomNavHeight - 100;
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xPositionKey, _xPosition);
      await prefs.setDouble(_yPositionKey, _yPosition);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _animationController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    setState(() {
      _xPosition += details.delta.dx;
      _yPosition += details.delta.dy;

      // Limiter aux bords de l'écran
      _xPosition = _xPosition.clamp(8.0, screenSize.width - _fabSize - 8);
      _yPosition = _yPosition.clamp(
        padding.top + 8,
        screenSize.height - _fabSize - widget.bottomNavHeight - 8,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _animationController.reverse();
    _savePosition();

    // Snap aux bords (optionnel - pour coller aux côtés)
    _snapToEdge();
  }

  void _snapToEdge() {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;

    setState(() {
      // Snap au bord le plus proche (gauche ou droite)
      if (_xPosition + _fabSize / 2 < centerX) {
        _xPosition = 16;
      } else {
        _xPosition = screenSize.width - _fabSize - 16;
      }
    });

    _savePosition();
  }

  void _openAIChat() {
    if (!_isDragging) {
      Navigator.pushNamed(context, AppRoutes.aiChat);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _openAIChat,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icône principale
                const Icon(
                  Icons.smart_toy,
                  color: AppTheme.background,
                  size: 28,
                ),
                // Indicateur de drag (petit point)
                if (_isDragging)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget helper pour utiliser le FAB dans un Stack
class DraggableAIChatFabOverlay extends StatelessWidget {
  final Widget child;
  final double bottomNavHeight;

  const DraggableAIChatFabOverlay({
    super.key,
    required this.child,
    this.bottomNavHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        DraggableAIChatFab(bottomNavHeight: bottomNavHeight),
      ],
    );
  }
}
