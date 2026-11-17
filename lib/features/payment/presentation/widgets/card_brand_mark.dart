import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/payment_method.dart';

/// Pastille de reseau de carte (Visa, Mastercard, Amex...) au format carte.
/// Reproduit la signature visuelle de chaque reseau pour qu'on reconnaisse
/// sa carte d'un coup d'oeil, sans embarquer de fichiers de logos.
class CardBrandMark extends StatelessWidget {
  final CardBrand? brand;
  final double width;

  const CardBrandMark({super.key, required this.brand, this.width = 44});

  @override
  Widget build(BuildContext context) {
    final height = width * 0.66;
    final isAmex = brand == CardBrand.amex;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isAmex ? const Color(0xFF1F72CD) : AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: isAmex ? null : Border.all(color: AppTheme.border),
      ),
      alignment: Alignment.center,
      child: _buildMark(height),
    );
  }

  Widget _buildMark(double height) {
    switch (brand) {
      case CardBrand.visa:
        return Text(
          'VISA',
          style: TextStyle(
            fontSize: height * 0.42,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.3,
            color: const Color(0xFF1A1F71),
          ),
        );
      case CardBrand.mastercard:
        final d = height * 0.56;
        return SizedBox(
          width: d * 1.6,
          height: d,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _circle(d, const Color(0xFFEB001B)),
              ),
              Positioned(
                right: 0,
                child:
                    _circle(d, const Color(0xFFF79E1B).withValues(alpha: 0.9)),
              ),
            ],
          ),
        );
      case CardBrand.amex:
        return Text(
          'AMEX',
          style: TextStyle(
            fontSize: height * 0.34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        );
      case CardBrand.discover:
        return Text(
          'DISCOVER',
          style: TextStyle(
            fontSize: height * 0.22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE55C20),
          ),
        );
      default:
        return Icon(
          Icons.credit_card_rounded,
          size: height * 0.6,
          color: AppTheme.textSecondary,
        );
    }
  }

  Widget _circle(double d, Color color) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
