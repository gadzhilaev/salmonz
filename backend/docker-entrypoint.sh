#!/bin/sh
set -eu

echo "Running Prisma migrate deploy..."
npx prisma migrate deploy

if [ "${RUN_SEED_ON_START:-true}" = "true" ]; then
  echo "Running Prisma seed..."
  npx prisma db seed || echo "Seed skipped or failed (non-fatal for restarts)"
fi

exec node dist/src/main.js
