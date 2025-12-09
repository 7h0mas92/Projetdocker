#!/bin/bash
set -e # Sortir immédiatement si une commande échoue

# Le script sera exécuté dans le répertoire /var/www/html

# 1. Afficher le contenu du répertoire
echo "=== Contenu du répertoire ==="
ls -la
pwd

# 2. Installation des dépendances Composer (toujours exécuté pour s'assurer que vendor existe)
echo "=== Installation des dépendances Composer ==="
if [ ! -f "composer.json" ]; then
    echo "ERREUR: composer.json non trouvé!"
    exit 1
fi

composer install --no-interaction --prefer-dist --optimize-autoloader

# Vérifier que vendor/autoload.php existe
if [ ! -f "vendor/autoload.php" ]; then
    echo "ERREUR: vendor/autoload.php n'existe pas après composer install!"
    exit 1
fi
echo "✓ Composer dependencies installed successfully"

# 3. Générer la clé d'application UNIQUEMENT si elle n'existe pas
echo "=== Vérification de la clé d'application ==="
if grep -q "APP_KEY=base64:.*" .env; then
    echo "✓ Clé APP_KEY déjà définie"
else
    echo "Génération de la clé d'application..."
    php artisan key:generate
fi

# 4. Installation des dépendances JS et compilation (pour le CSS/JS)
echo "=== Installation des dépendances Node.js ==="
if [ ! -d "node_modules" ]; then
    echo "Installation des dépendances Node et build..."
    npm install
    npm run build
    echo "✓ Node.js dependencies installed"
else
    echo "✓ Dossier node_modules déjà présent"
fi

# 5. Migration et Seeding (Uniquement pour le premier serveur, car la DB est partagée)
echo "=== Vérification du CONTAINER_NAME: $CONTAINER_NAME ==="
if [ "$CONTAINER_NAME" = "app_server1" ]; then
    # Attendre que MySQL soit prêt
    echo "Attente de la base de données..."
    sleep 10
    echo "Lancement des migrations et seeding..."
    php artisan migrate:fresh --seed
    echo "✓ Migration et Seeding terminés"
else
    echo "✓ Instance $CONTAINER_NAME, migrations ignorées"
fi

# 6. Définir les permissions correctes
echo "=== Définition des permissions ==="
chmod -R 775 storage bootstrap/cache
echo "✓ Permissions définies"

# 7. Lancer le processus PHP-FPM
echo "=== Lancement de PHP-FPM ==="
exec php-fpm
