import 'package:deneige_auto/features/auth/domain/entities/user.dart';
import 'package:deneige_auto/features/auth/data/models/user_model.dart';

/// Fixtures pour les tests User
class UserFixtures {
  /// Cree un UserModel client pour les tests data layer
  static UserModel createClientModel({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? 'user-client-123',
      email: email ?? 'client@test.com',
      name: name ?? 'Jean Dupont',
      phoneNumber: phoneNumber ?? '+1234567890',
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      role: UserRole.client,
    );
  }

  /// Cree un UserModel worker pour les tests data layer
  static UserModel createWorkerModel({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? 'user-worker-456',
      email: email ?? 'worker@test.com',
      name: name ?? 'Pierre Martin',
      phoneNumber: phoneNumber ?? '+1987654321',
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      role: UserRole.snowWorker,
    );
  }
  /// Cree un utilisateur client pour les tests
  static User createClient({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? 'user-client-123',
      email: email ?? 'client@test.com',
      name: name ?? 'Jean Dupont',
      phoneNumber: phoneNumber ?? '+1234567890',
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      role: UserRole.client,
    );
  }

  /// Cree un utilisateur deneigeur pour les tests
  static User createWorker({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? 'user-worker-456',
      email: email ?? 'worker@test.com',
      name: name ?? 'Pierre Martin',
      phoneNumber: phoneNumber ?? '+1987654321',
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      role: UserRole.snowWorker,
    );
  }

  /// Cree un utilisateur admin pour les tests
  static User createAdmin({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? 'user-admin-789',
      email: email ?? 'admin@test.com',
      name: name ?? 'Admin User',
      phoneNumber: phoneNumber ?? '+1555555555',
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      role: UserRole.admin,
    );
  }

  /// Cree une liste d'utilisateurs clients
  static List<User> createClientList(int count) {
    return List.generate(
      count,
      (index) => createClient(
        id: 'user-client-$index',
        email: 'client$index@test.com',
        name: 'Client $index',
      ),
    );
  }

  /// Cree une liste d'utilisateurs workers
  static List<User> createWorkerList(int count) {
    return List.generate(
      count,
      (index) => createWorker(
        id: 'user-worker-$index',
        email: 'worker$index@test.com',
        name: 'Worker $index',
      ),
    );
  }
}
