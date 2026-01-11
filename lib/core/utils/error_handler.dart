import 'dart:io';

import 'package:dio/dio.dart';

/// Gestionnaire d'erreurs centralisé pour l'application
/// Fournit des messages d'erreur conviviaux en français
class ErrorHandler {
  /// Convertit une exception en message d'erreur lisible
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    } else if (error is FormatException) {
      return 'Erreur de format de données. Veuillez réessayer.';
    } else if (error is TypeError) {
      return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    } else if (error is String) {
      return error;
    } else if (error != null && error.toString().isNotEmpty) {
      return error.toString();
    }
    return 'Une erreur inattendue s\'est produite.';
  }

  /// Gère les erreurs Dio spécifiquement
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'La connexion a expiré. Vérifiez votre connexion internet.';

      case DioExceptionType.sendTimeout:
        return 'L\'envoi des données a pris trop de temps. Réessayez.';

      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre. Réessayez.';

      case DioExceptionType.badCertificate:
        return 'Erreur de sécurité. Contactez le support.';

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);

      case DioExceptionType.cancel:
        return 'La requête a été annulée.';

      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'Pas de connexion internet. Vérifiez votre réseau.';
        }
        return 'Une erreur de connexion s\'est produite.';
    }
  }

  /// Gère les erreurs HTTP basées sur le code de statut
  static String _handleHttpError(Response? response) {
    if (response == null) {
      return 'Aucune réponse du serveur.';
    }

    // Essayer d'extraire le message du serveur
    String? serverMessage;
    if (response.data is Map) {
      serverMessage = response.data['message'] as String?;
    }

    switch (response.statusCode) {
      case 400:
        return serverMessage ??
            'Requête invalide. Vérifiez les informations saisies.';

      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';

      case 403:
        return serverMessage ??
            'Vous n\'avez pas les droits pour cette action.';

      case 404:
        return serverMessage ?? 'Ressource non trouvée.';

      case 409:
        return serverMessage ?? 'Conflit avec les données existantes.';

      case 422:
        return _extractValidationErrors(response.data) ??
            serverMessage ??
            'Données invalides. Vérifiez les champs du formulaire.';

      case 429:
        final retryAfter = response.data['retryAfter'];
        if (retryAfter != null) {
          final minutes = (retryAfter / 60).ceil();
          return 'Trop de tentatives. Réessayez dans $minutes minute${minutes > 1 ? 's' : ''}.';
        }
        return serverMessage ?? 'Trop de requêtes. Veuillez patienter.';

      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard.';

      case 502:
        return 'Le serveur est temporairement indisponible.';

      case 503:
        return 'Service en maintenance. Veuillez réessayer plus tard.';

      case 504:
        return 'Le serveur ne répond pas. Réessayez plus tard.';

      default:
        if (response.statusCode != null && response.statusCode! >= 500) {
          return 'Erreur serveur (${response.statusCode}). Réessayez plus tard.';
        }
        return serverMessage ??
            'Erreur ${response.statusCode}. Veuillez réessayer.';
    }
  }

  /// Extrait les erreurs de validation d'une réponse 422
  static String? _extractValidationErrors(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors == null) return null;

    if (errors is List && errors.isNotEmpty) {
      // Format: [{ "field": "email", "message": "Email invalide" }]
      final messages = errors
          .map((e) => e['message'] ?? e['msg'] ?? e.toString())
          .take(3)
          .join('\n');
      return messages;
    }

    if (errors is Map) {
      // Format: { "email": ["Email invalide"], "password": ["Trop court"] }
      final messages = errors.entries
          .map((e) {
            final fieldErrors = e.value;
            if (fieldErrors is List && fieldErrors.isNotEmpty) {
              return fieldErrors.first.toString();
            }
            return fieldErrors.toString();
          })
          .take(3)
          .join('\n');
      return messages;
    }

    return null;
  }

  /// Vérifie si l'erreur est une erreur réseau
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          (error.type == DioExceptionType.unknown &&
              error.error is SocketException);
    }
    return error is SocketException;
  }

  /// Vérifie si l'erreur nécessite une reconnexion
  static bool requiresReauth(dynamic error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }
    return false;
  }

  /// Vérifie si l'erreur est due au rate limiting
  static bool isRateLimited(dynamic error) {
    if (error is DioException && error.response?.statusCode == 429) {
      return true;
    }
    return false;
  }

  /// Obtient le temps d'attente en secondes pour le rate limiting
  static int? getRetryAfterSeconds(dynamic error) {
    if (error is DioException && error.response?.statusCode == 429) {
      final data = error.response?.data;
      if (data is Map && data['retryAfter'] != null) {
        return data['retryAfter'] as int?;
      }
    }
    return null;
  }
}

/// Extension pour faciliter l'utilisation de l'error handler
extension ErrorHandlerExtension on Object {
  String get userFriendlyMessage => ErrorHandler.getErrorMessage(this);
}
