import 'package:equatable/equatable.dart';

/// Rôles disponibles dans l'application Deneige Auto.
enum UserRole { client, snowWorker, admin }

/// Entité User de la couche domaine.
/// Représente un utilisateur authentifié avec son rôle et ses informations de profil.
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    required this.role,
  });

  @override
  List<Object?> get props =>
      [id, email, name, phoneNumber, photoUrl, createdAt, role];

  /// Extrait le prénom à partir du nom complet.
  String? get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  /// Extrait le nom de famille (tout après le premier espace).
  String? get lastName {
    final parts = name.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : null;
  }
}
