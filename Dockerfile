# Dockerfile pour Deneige-auto Flutter App
# Utilisé pour reproduire l'environnement CI localement

FROM ghcr.io/cirruslabs/flutter:3.35.7

# Installer des outils utiles
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances d'abord (pour le cache Docker)
COPY pubspec.yaml pubspec.lock ./

# Installer les dépendances Flutter
RUN flutter pub get

# Copier le reste du code
COPY . .

# Réinstaller les dépendances avec tout le code
RUN flutter pub get

# Commande par défaut : afficher l'aide
CMD ["flutter", "--version"]
