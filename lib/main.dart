// Imports nécessaires pour Flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';


// Import du widget racine de l'application
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'deneigeauto_app.dart';

// Import de l'injection de dépendances
import 'core/di/injection_container.dart';

/// Point d'entrée principal de l'application Deneige Auto
/// Cette fonction est appelée au démarrage de l'application
void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ Initialiser Stripe
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
    print('✅ Stripe initialisé');

    // Initialiser les dépendances
    await di.initializeDependencies();

    runApp(const DeneigeAutoApp());
  }