import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Montant en dollars dans la langue de l'app : "31,47 $" en francais,
/// "$31.47" en anglais.
String formatMoney(BuildContext context, double amount, {int decimals = 2}) =>
    NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '\$',
      decimalDigits: decimals,
    ).format(amount);
