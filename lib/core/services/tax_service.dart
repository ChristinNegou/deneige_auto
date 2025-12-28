/// Service de calcul des taxes selon la province canadienne
class TaxService {
  /// Singleton
  static final TaxService _instance = TaxService._internal();
  factory TaxService() => _instance;
  TaxService._internal();

  /// Données des taxes par province (2024)
  static const Map<String, ProvinceTaxInfo> _provinceTaxes = {
    // Provinces avec HST (taxe harmonisée)
    'ON': ProvinceTaxInfo(
      code: 'ON',
      name: 'Ontario',
      gstRate: 0.05,
      pstRate: 0.08,
      isHST: true,
      hstRate: 0.13,
    ),
    'NB': ProvinceTaxInfo(
      code: 'NB',
      name: 'Nouveau-Brunswick',
      gstRate: 0.05,
      pstRate: 0.10,
      isHST: true,
      hstRate: 0.15,
    ),
    'NL': ProvinceTaxInfo(
      code: 'NL',
      name: 'Terre-Neuve-et-Labrador',
      gstRate: 0.05,
      pstRate: 0.10,
      isHST: true,
      hstRate: 0.15,
    ),
    'NS': ProvinceTaxInfo(
      code: 'NS',
      name: 'Nouvelle-Écosse',
      gstRate: 0.05,
      pstRate: 0.10,
      isHST: true,
      hstRate: 0.15,
    ),
    'PE': ProvinceTaxInfo(
      code: 'PE',
      name: 'Île-du-Prince-Édouard',
      gstRate: 0.05,
      pstRate: 0.10,
      isHST: true,
      hstRate: 0.15,
    ),

    // Provinces avec GST + PST séparées
    'QC': ProvinceTaxInfo(
      code: 'QC',
      name: 'Québec',
      gstRate: 0.05,
      pstRate: 0.09975,
      isHST: false,
      federalTaxName: 'TPS',
      provincialTaxName: 'TVQ',
    ),
    'BC': ProvinceTaxInfo(
      code: 'BC',
      name: 'Colombie-Britannique',
      gstRate: 0.05,
      pstRate: 0.07,
      isHST: false,
    ),
    'SK': ProvinceTaxInfo(
      code: 'SK',
      name: 'Saskatchewan',
      gstRate: 0.05,
      pstRate: 0.06,
      isHST: false,
    ),
    'MB': ProvinceTaxInfo(
      code: 'MB',
      name: 'Manitoba',
      gstRate: 0.05,
      pstRate: 0.07,
      isHST: false,
    ),

    // Provinces/Territoires avec GST seulement
    'AB': ProvinceTaxInfo(
      code: 'AB',
      name: 'Alberta',
      gstRate: 0.05,
      pstRate: 0.0,
      isHST: false,
    ),
    'NT': ProvinceTaxInfo(
      code: 'NT',
      name: 'Territoires du Nord-Ouest',
      gstRate: 0.05,
      pstRate: 0.0,
      isHST: false,
    ),
    'NU': ProvinceTaxInfo(
      code: 'NU',
      name: 'Nunavut',
      gstRate: 0.05,
      pstRate: 0.0,
      isHST: false,
    ),
    'YT': ProvinceTaxInfo(
      code: 'YT',
      name: 'Yukon',
      gstRate: 0.05,
      pstRate: 0.0,
      isHST: false,
    ),
  };

  /// Province par défaut (Québec)
  static const String defaultProvinceCode = 'QC';

  /// Obtenir les infos de taxe pour une province
  ProvinceTaxInfo getTaxInfo(String provinceCode) {
    return _provinceTaxes[provinceCode.toUpperCase()] ??
           _provinceTaxes[defaultProvinceCode]!;
  }

  /// Détecter la province à partir d'une adresse
  String detectProvinceFromAddress(String? address) {
    if (address == null || address.isEmpty) {
      return defaultProvinceCode;
    }

    final addressUpper = address.toUpperCase();

    // Chercher les codes postaux canadiens (format: A1A 1A1)
    final postalCodeRegex = RegExp(r'\b([A-Z])\d[A-Z]\s?\d[A-Z]\d\b');
    final match = postalCodeRegex.firstMatch(addressUpper);

    if (match != null) {
      final firstLetter = match.group(1);
      final province = _getProvinceFromPostalCode(firstLetter!);
      if (province != null) return province;
    }

    // Chercher les noms/abréviations de provinces dans l'adresse
    for (final entry in _provinceTaxes.entries) {
      final code = entry.key;
      final info = entry.value;

      // Chercher le code (ON, QC, etc.)
      if (addressUpper.contains(RegExp('\\b$code\\b'))) {
        return code;
      }

      // Chercher le nom complet
      if (addressUpper.contains(info.name.toUpperCase())) {
        return code;
      }
    }

    // Chercher des variantes communes
    final provincePatterns = {
      'ONTARIO': 'ON',
      'QUEBEC': 'QC',
      'QUÉBEC': 'QC',
      'BRITISH COLUMBIA': 'BC',
      'COLOMBIE-BRITANNIQUE': 'BC',
      'ALBERTA': 'AB',
      'SASKATCHEWAN': 'SK',
      'MANITOBA': 'MB',
      'NEW BRUNSWICK': 'NB',
      'NOUVEAU-BRUNSWICK': 'NB',
      'NOVA SCOTIA': 'NS',
      'NOUVELLE-ÉCOSSE': 'NS',
      'NEWFOUNDLAND': 'NL',
      'TERRE-NEUVE': 'NL',
      'PRINCE EDWARD': 'PE',
      'ÎLE-DU-PRINCE': 'PE',
      'NORTHWEST': 'NT',
      'NORD-OUEST': 'NT',
      'NUNAVUT': 'NU',
      'YUKON': 'YT',
    };

    for (final entry in provincePatterns.entries) {
      if (addressUpper.contains(entry.key)) {
        return entry.value;
      }
    }

    return defaultProvinceCode;
  }

  /// Obtenir la province à partir de la première lettre du code postal
  String? _getProvinceFromPostalCode(String firstLetter) {
    // Mapping première lettre code postal -> province
    const postalCodeMap = {
      'A': 'NL', // Terre-Neuve-et-Labrador
      'B': 'NS', // Nouvelle-Écosse
      'C': 'PE', // Île-du-Prince-Édouard
      'E': 'NB', // Nouveau-Brunswick
      'G': 'QC', // Québec (Est)
      'H': 'QC', // Québec (Montréal)
      'J': 'QC', // Québec (Ouest)
      'K': 'ON', // Ontario (Est)
      'L': 'ON', // Ontario (Centre)
      'M': 'ON', // Ontario (Toronto)
      'N': 'ON', // Ontario (Sud-Ouest)
      'P': 'ON', // Ontario (Nord)
      'R': 'MB', // Manitoba
      'S': 'SK', // Saskatchewan
      'T': 'AB', // Alberta
      'V': 'BC', // Colombie-Britannique
      'X': 'NT', // Territoires du Nord-Ouest / Nunavut
      'Y': 'YT', // Yukon
    };

    return postalCodeMap[firstLetter];
  }

  /// Calculer les taxes pour un montant donné
  TaxCalculation calculateTaxes(double subtotal, String provinceCode) {
    final taxInfo = getTaxInfo(provinceCode);

    if (taxInfo.isHST) {
      // HST combinée
      final hst = subtotal * taxInfo.hstRate;
      return TaxCalculation(
        subtotal: subtotal,
        federalTax: hst,
        federalTaxRate: taxInfo.hstRate,
        federalTaxName: 'HST',
        provincialTax: 0,
        provincialTaxRate: 0,
        provincialTaxName: '',
        total: subtotal + hst,
        provinceCode: provinceCode,
        provinceName: taxInfo.name,
        isHST: true,
      );
    } else {
      // GST/TPS + PST/TVQ séparées
      final gst = subtotal * taxInfo.gstRate;
      final pst = subtotal * taxInfo.pstRate;

      return TaxCalculation(
        subtotal: subtotal,
        federalTax: gst,
        federalTaxRate: taxInfo.gstRate,
        federalTaxName: taxInfo.federalTaxName,
        provincialTax: pst,
        provincialTaxRate: taxInfo.pstRate,
        provincialTaxName: taxInfo.provincialTaxName,
        total: subtotal + gst + pst,
        provinceCode: provinceCode,
        provinceName: taxInfo.name,
        isHST: false,
      );
    }
  }
}

/// Informations sur les taxes d'une province
class ProvinceTaxInfo {
  final String code;
  final String name;
  final double gstRate;      // Taux GST/TPS fédéral
  final double pstRate;      // Taux PST/TVQ provincial
  final bool isHST;          // Si utilise HST combinée
  final double hstRate;      // Taux HST si applicable
  final String federalTaxName;
  final String provincialTaxName;

  const ProvinceTaxInfo({
    required this.code,
    required this.name,
    required this.gstRate,
    required this.pstRate,
    required this.isHST,
    this.hstRate = 0.0,
    this.federalTaxName = 'GST',
    this.provincialTaxName = 'PST',
  });

  double get totalTaxRate => isHST ? hstRate : (gstRate + pstRate);
}

/// Résultat du calcul des taxes
class TaxCalculation {
  final double subtotal;
  final double federalTax;
  final double federalTaxRate;
  final String federalTaxName;
  final double provincialTax;
  final double provincialTaxRate;
  final String provincialTaxName;
  final double total;
  final String provinceCode;
  final String provinceName;
  final bool isHST;

  const TaxCalculation({
    required this.subtotal,
    required this.federalTax,
    required this.federalTaxRate,
    required this.federalTaxName,
    required this.provincialTax,
    required this.provincialTaxRate,
    required this.provincialTaxName,
    required this.total,
    required this.provinceCode,
    required this.provinceName,
    required this.isHST,
  });

  double get totalTaxes => federalTax + provincialTax;

  String get federalTaxLabel =>
      '$federalTaxName (${(federalTaxRate * 100).toStringAsFixed(isHST ? 0 : 0)}%)';

  String get provincialTaxLabel =>
      provincialTaxRate > 0
          ? '$provincialTaxName (${(provincialTaxRate * 100).toStringAsFixed(provincialTaxRate == 0.09975 ? 3 : 0)}%)'
          : '';
}
