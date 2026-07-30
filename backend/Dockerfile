# Multi-stage NestJS API image (non-root)
FROM node:22-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build
RUN npm prune --omit=dev

FROM node:22-bookworm-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --system --gid 1001 nestjs \
  && useradd --system --uid 1001 --gid nestjs nestjs
COPY --from=build --chown=nestjs:nestjs /app/dist ./dist
COPY --from=build --chown=nestjs:nestjs /app/node_modules ./node_modules
COPY --from=build --chown=nestjs:nestjs /app/package.json ./package.json
COPY --from=build --chown=nestjs:nestjs /app/prisma ./prisma
COPY --from=build --chown=nestjs:nestjs /app/generated ./generated
COPY --from=build --chown=nestjs:nestjs /app/prisma.config.ts ./prisma.config.ts
COPY --from=build --chown=nestjs:nestjs /app/docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh
USER nestjs
EXPOSE 3000
ENTRYPOINT ["/app/docker-entrypoint.sh"]
