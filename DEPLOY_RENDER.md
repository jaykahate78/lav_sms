# LAV SMS — Render + Neon isolated demo

## Infrastructure
- Existing Render web service: `lav_sms` (branch `deploy/render-school-demo`).
- Separate Neon project: `lavsms-school-demo` using PostgreSQL 16, Singapore region.
- No paid Render MySQL service, and no connection to existing Neon projects.
- Apache serves only `public/`, Docker installs `pdo_pgsql`, secure SSL is required for Neon.
- Laravel migrations and synthetic seed data are executed at app startup; seed runs only if users table is empty.
- All secrets are in Render Environment, **never committed to Git**.

## Render settings
Set APP_KEY to a strong randomly generated Laravel base64 key and DEMO_SEED_PASSWORD to a different 20+ character password.
Set DB_CONNECTION=pgsql, DB_SSLMODE=require, DB_HOST, DB_PORT=5432, DB_DATABASE, DB_USERNAME, DB_PASSWORD from the *dedicated* Neon project.
Set APP_ENV=production, APP_DEBUG=false, SESSION_SECURE_COOKIE=true, DEMO_SEED=true.
Use APP_URL=https://lav-sms-iw6x.onrender.com.

## Known limits
Legacy Laravel 8 code may need PostgreSQL-specific migration and seed fixes. Never enter real student data; original project has other unreviewed security issues. Demo access is for internal sales only until the app is tested and secured.
Render Free web instances may sleep; file uploads and file sessions are ephemeral. For persistent uploaded documents, configure external object storage and upgrade to a supported Laravel version before production use.

## Local testing
Use docker compose with a local PostgreSQL instance and a secret DB_PASSWORD; set DB_SSLMODE=prefer for local only. `docker compose up --build` then visit http://localhost:8000.
