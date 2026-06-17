# ============================================================
# Dockerfile - DevOps Fase 2
# Aplicação Node.js com build multi-estágio
# ============================================================

# Estágio 1: Instalação de dependências
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production

# ============================================================
# Estágio 2: Imagem final de produção
FROM node:22-alpine AS runner
WORKDIR /app

# Cria usuário não-root por segurança
RUN addgroup --system --gid 1001 nodejs && \
  adduser --system --uid 1001 nodeuser

# Copia dependências e código-fonte
COPY --from=deps /app/node_modules ./node_modules
COPY app/ ./app/
COPY package.json ./

# Define usuário não-root
USER nodeuser

# Expõe a porta da aplicação
EXPOSE 3000

# Health check integrado
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Variáveis de ambiente padrão
ENV NODE_ENV=production \
  PORT=3000

CMD ["node", "app/index.js"]
