#!/bin/bash
set -e 

echo "=== Contenu du répertoire ==="
ls -la
pwd

echo "=== Installation des dépendances Composer ==="
if [ ! -f "composer.json" ]; then
    echo "ERREUR: composer.json non trouvé!"
    exit 1
fi

composer install --no-interaction --prefer-dist --optimize-autoloader

if [ ! -f "vendor/autoload.php" ]; then
    echo "ERREUR: vendor/autoload.php n'existe pas après composer install!"
    exit 1
fi
echo "✓ Composer dependencies installed successfully"

echo "=== Vérification de la clé d'application ==="
if grep -q "APP_KEY=base64:.*" .env; then
    echo "✓ Clé APP_KEY déjà définie"
else
    echo "Génération de la clé d'application..."
    php artisan key:generate
fi

echo "=== Installation des dépendances Node.js ==="
if [ ! -d "node_modules" ]; then
    echo "Installation des dépendances Node et build..."
    npm install
    npm run build
    echo "✓ Node.js dependencies installed"
else
    echo "✓ Dossier node_modules déjà présent"
fi

echo "=== Vérification du CONTAINER_NAME: $CONTAINER_NAME ==="
if [ "$CONTAINER_NAME" = "app_server2" ]; then
    
    echo "Attente de la base de données..."
    sleep 10
    echo "Lancement des migrations et seeding..."
    php artisan migrate:fresh --seed
    echo "✓ Migration et Seeding terminés"
else
    echo "✓ Instance $CONTAINER_NAME, migrations ignorées"
fi

echo "=== Définition des permissions ==="
chmod -R 775 storage bootstrap/cache
echo "✓ Permissions définies"

echo "=== Lancement de PHP-FPM ==="
exec php-fpm
