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
    'Noir': Color(0xFF16181B),
    'Gris': Color(0xFF8A9097),
    'Rouge': Color(0xFFC0392B),
    'Bleu': Color(0xFF2C5D9E),
    'Vert': Color(0xFF2E7D4F),
    'Jaune': Color(0xFFE8C547),
    'Orange': Color(0xFFE67E22),
    'Argent': Color(0xFFC3C8CE),
    'Brun': Color(0xFF795548),
    'Beige': Color(0xFFE8DCC0),
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
        style: const TextStyle(
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
