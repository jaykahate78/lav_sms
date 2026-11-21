#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP_KEY:?Set APP_KEY as base64:... in Render environment}"
: "${DB_HOST:?Set DB_HOST}"
: "${DB_DATABASE:?Set DB_DATABASE}"
: "${DB_USERNAME:?Set DB_USERNAME}"
: "${DB_PASSWORD:?Set DB_PASSWORD}"
if [[ "$APP_KEY" != base64:* ]]; then
  echo "APP_KEY must use Laravel base64: format" >&2
  exit 1
fi

export APP_URL="${APP_URL:-${RENDER_EXTERNAL_URL:-http://localhost:10000}}"
if [[ "$APP_URL" == https://* ]]; then
  export SESSION_SECURE_COOKIE=true
fi

echo "Waiting for MySQL..."
connected=0
for i in $(seq 1 60); do
  if php -r 'try { new PDO("mysql:host=".getenv("DB_HOST").";port=".(getenv("DB_PORT") ?: "3306").";dbname=".getenv("DB_DATABASE"), getenv("DB_USERNAME"), getenv("DB_PASSWORD"), [PDO::ATTR_TIMEOUT => 3]); } catch (Throwable $e) { exit(1); }'; then
    connected=1
    break
  fi
  sleep 2
done
if [[ "$connected" != 1 ]]; then
  echo "MySQL connection unavailable. Refusing to serve broken application." >&2
  exit 1
fi

php artisan package:discover --ansi
php artisan optimize:clear
php artisan migrate --force

if [[ "${DEMO_SEED:-false}" == "true" ]]; then
  : "${DEMO_SEED_PASSWORD:?Set a unique strong DEMO_SEED_PASSWORD for synthetic demonstration accounts}"
  if [[ "${#DEMO_SEED_PASSWORD}" -lt 16 ]]; then
    echo "DEMO_SEED_PASSWORD must be at least 16 characters" >&2
    exit 1
  fi
  existing=$(php -r 'require "vendor/autoload.php"; $a=require "bootstrap/app.php"; $a->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap(); echo Illuminate\Support\Facades\DB::table("users")->count();')
  if [[ "$existing" == 0 ]]; then
    echo "Seeding synthetic demo data only for empty database..."
    php artisan db:seed --force
  fi
fi
php artisan storage:link >/dev/null 2>&1 || true
chown -R www-data:www-data storage bootstrap/cache
exec apache2-foreground
