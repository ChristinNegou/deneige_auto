import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reservation/domain/entities/vehicle.dart';

/// Icone Material correspondant au type de vehicule.
IconData vehicleTypeIcon(VehicleType type) {
  switch (type) {
    case VehicleType.suv:
      return Icons.airport_shuttle_rounded;
    case VehicleType.truck:
      return Icons.local_shipping_rounded;
    case VehicleType.van:
      return Icons.rv_hookup_rounded;
    case VehicleType.motorcycle:
      return Icons.two_wheeler_rounded;
    default:
      return Icons.directions_car_filled_rounded;
  }
}

/// Couleur reelle de carrosserie (pas une couleur de l'interface).
Color vehicleBodyColor(String colorName) {
  const colors = {
    'Blanc': Color(0xFFFFFFFF),
    'Blanc nacré': Color(0xFFF4F1E8),
    'Argent': Color(0xFFC3C8CE),
    'Gris': Color(0xFF8A9097),
    'Gris foncé': Color(0xFF4A4F55),
    'Noir': Color(0xFF16181B),
    'Beige': Color(0xFFE8DCC0),
    'Champagne': Color(0xFFD9C7A3),
    'Brun': Color(0xFF795548),
    'Bronze': Color(0xFF9C6B3C),
    'Or': Color(0xFFC9A646),
    'Jaune': Color(0xFFE8C547),
    'Orange': Color(0xFFE67E22),
    'Rouge': Color(0xFFC0392B),
    'Bordeaux': Color(0xFF6E1E2B),
    'Rose': Color(0xFFE59AB0),
    'Violet': Color(0xFF5E3A87),
    'Bleu ciel': Color(0xFF8DB9E2),
    'Bleu': Color(0xFF2C5D9E),
    'Bleu marine': Color(0xFF1B2A4A),
    'Turquoise': Color(0xFF1E9AA0),
    'Vert': Color(0xFF2E7D4F),
    'Vert foncé': Color(0xFF1F4A33),
  };
  return colors[colorName] ?? AppTheme.textTertiary;
}

/// Pastille de couleur de carrosserie, bordee pour rester visible (blanc, argent).
class VehicleColorDot extends StatelessWidget {
  final String colorName;
  final double size;

  const VehicleColorDot({super.key, required this.colorName, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: vehicleBodyColor(colorName),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
    );
  }
}

/// Plaque d'immatriculation : fond blanc, cadre et lettrage bleu nuit.
class LicensePlate extends StatelessWidget {
  final String plate;

  const LicensePlate({super.key, required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primary, width: 1.2),
      ),
      child: Text(
        plate.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppTheme.primary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
