FROM node:20-alpine AS base

FROM base AS builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
WORKDIR /app

COPY package.json ./
COPY .npmrc ./

RUN corepack enable
RUN npm config set registry https://registry.npmmirror.com/
RUN pnpm i
RUN pnpm add sharp

COPY . .

ENV NEXT_PUBLIC_BASE_PATH ""

# Sentry
ENV NEXT_PUBLIC_SENTRY_DSN ""
ENV SENTRY_ORG ""
ENV SENTRY_PROJECT ""

ENV GENERATE_SOURCEMAP=false
ENV NODE_OPTIONS=--max_old_space_size=8192

RUN npm run build:docker

FROM base AS runner
WORKDIR /app

RUN apk add proxychains-ng
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/server ./.next/server
COPY --from=builder /app/node_modules/sharp ./node_modules/sharp

EXPOSE 3040

ENV NODE_ENV production
ENV PROXY_URL=""
ENV HOSTNAME "0.0.0.0"
ENV PORT=3040

# Mid Journey
ENV MIDJOURNEY_PROXY_URL ""
ENV MIDJOURNEY_PROXY_API_SECRET ""
ENV METADATA_BASE_URL ""
ENV IMGUR_CLIENT_ID ""

CMD ["node", "server.js"]
