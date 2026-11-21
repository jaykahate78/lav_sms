#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP_KEY:?Set APP_KEY as base64:... in Render environment}"
: "${DB_HOST:?Set DB_HOST}"
: "${DB_DATABASE:?Set DB_DATABASE}"
: "${DB_USERNAME:?Set DB_USERNAME}"
: "${DB_PASSWORD:?Set DB_PASSWORD}"
: "${NEON_ENDPOINT_ID:?Set NEON_ENDPOINT_ID from Neon hostname}"
if [[ "${DB_CONNECTION:-}" != pgsql ]]; then
  echo "DB_CONNECTION must be pgsql for Neon" >&2
  exit 1
fi
if [[ "$APP_KEY" != base64:* ]]; then
  echo "APP_KEY must use Laravel base64: format" >&2
  exit 1
fi

export APP_URL="${APP_URL:-${RENDER_EXTERNAL_URL:-http://localhost:10000}}"
if [[ "$APP_URL" == https://* ]]; then
  export SESSION_SECURE_COOKIE=true
fi

echo "Waiting for Neon PostgreSQL..."
connected=0
for i in $(seq 1 12); do
  if php -r 'try { new PDO("pgsql:host=".getenv("DB_HOST").";port=".(getenv("DB_PORT") ?: "5432").";dbname=".getenv("DB_DATABASE").";sslmode=require;connect_timeout=4;options=endpoint=".getenv("NEON_ENDPOINT_ID"), getenv("DB_USERNAME"), getenv("DB_PASSWORD")); } catch (Throwable $e) {  $msg = strtolower($e->getMessage()); $category = (strpos($msg, "could not translate") !== false || strpos($msg, "name or service not known") !== false) ? "dns" : ((strpos($msg, "password authentication failed") !== false || strpos($msg, "no pg_hba.conf entry") !== false) ? "auth" : ((strpos($msg, "timeout") !== false || strpos($msg, "timed out") !== false) ? "timeout" : ((strpos($msg, "refused") !== false || strpos($msg, "network is unreachable") !== false) ? "network" : "other")));  $detail = substr(str_replace([getenv("DB_PASSWORD"), getenv("APP_KEY"), getenv("DEMO_SEED_PASSWORD")], "[REDACTED]", $e->getMessage()), 0, 480); fwrite(STDERR, "Neon connectivity: category=" . $category . " code=" . $e->getCode() . " detail=" . $detail . "\\n"); exit(1); }'; then
    connected=1
    break
  fi
  sleep 2
done
if [[ "$connected" != 1 ]]; then
  echo "Neon PostgreSQL connection unavailable. Refusing to serve broken application." >&2
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
