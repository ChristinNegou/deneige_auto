import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// FAB déplaçable pour le chatbot IA
/// Peut être glissé n'importe où sur l'écran et mémorise sa position
class DraggableAIChatFab extends StatefulWidget {
  final double bottomNavHeight;
  final String screenId;

  const DraggableAIChatFab({
    super.key,
    this.bottomNavHeight = 80,
    this.screenId = 'default',
  });

  @override
  State<DraggableAIChatFab> createState() => _DraggableAIChatFabState();
}

class _DraggableAIChatFabState extends State<DraggableAIChatFab>
    with SingleTickerProviderStateMixin {
  // Position du FAB (null = utiliser position par défaut)
  double? _xPosition;
  double? _yPosition;
  bool _isDragging = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Taille du FAB
  static const double _fabSize = 56;

  // Clés pour SharedPreferences (dynamiques par écran)
  String get _xPositionKey => 'ai_chat_fab_x_${widget.screenId}';
  String get _yPositionKey => 'ai_chat_fab_y_${widget.screenId}';

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
    _loadSavedPosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble(_xPositionKey);
      final savedY = prefs.getDouble(_yPositionKey);

      if (savedX != null && savedY != null && mounted) {
        setState(() {
          _xPosition = savedX;
          _yPosition = savedY;
        });
      }
    } catch (e) {
      // Ignorer - on utilisera la position par défaut
    }
  }

  // Calcule la position par défaut basée sur la taille de l'écran
  double _getDefaultX(Size screenSize) {
    return screenSize.width - _fabSize - 16;
  }

  double _getDefaultY(Size screenSize) {
    return screenSize.height - _fabSize - widget.bottomNavHeight - 100;
  }

  // Valide et retourne une position dans les limites
  double _getValidX(double x, Size screenSize) {
    return x.clamp(8.0, screenSize.width - _fabSize - 8);
  }

  double _getValidY(double y, Size screenSize, EdgeInsets padding) {
    return y.clamp(
      padding.top + 8,
      screenSize.height - _fabSize - widget.bottomNavHeight - 8,
    );
  }

  Future<void> _savePosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_xPositionKey, x);
      await prefs.setDouble(_yPositionKey, y);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _animationController.forward();
  }

  void _onPanUpdate(
      DragUpdateDetails details, Size screenSize, EdgeInsets padding) {
    setState(() {
      final currentX = _xPosition ?? _getDefaultX(screenSize);
      final currentY = _yPosition ?? _getDefaultY(screenSize);

      _xPosition = _getValidX(currentX + details.delta.dx, screenSize);
      _yPosition = _getValidY(currentY + details.delta.dy, screenSize, padding);
    });
  }

  void _onPanEnd(DragEndDetails details, Size screenSize, EdgeInsets padding) {
    setState(() => _isDragging = false);
    _animationController.reverse();

    // Snap aux bords
    final currentX = _xPosition ?? _getDefaultX(screenSize);
    final centerX = screenSize.width / 2;
    final newX = (currentX + _fabSize / 2 < centerX)
        ? 16.0
        : screenSize.width - _fabSize - 16;

    setState(() {
      _xPosition = newX;
    });

    _savePosition(newX, _yPosition ?? _getDefaultY(screenSize));
  }

  void _openAIChat() {
    if (!_isDragging) {
      Navigator.pushNamed(context, AppRoutes.aiChat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Calculer la position effective
    double effectiveX;
    double effectiveY;

    if (_xPosition != null && _yPosition != null) {
      // Utiliser la position sauvegardée mais la valider
      effectiveX = _getValidX(_xPosition!, screenSize);
      effectiveY = _getValidY(_yPosition!, screenSize, padding);
    } else {
      // Position par défaut
      effectiveX = _getDefaultX(screenSize);
      effectiveY = _getDefaultY(screenSize);
    }

    return Positioned(
      left: effectiveX,
      top: effectiveY,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: (details) => _onPanUpdate(details, screenSize, padding),
        onPanEnd: (details) => _onPanEnd(details, screenSize, padding),
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
