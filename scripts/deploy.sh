#!/bin/bash
# ============================================================
# Script de Deploy com Auto-Rollback - DevOps Fase 2
#
# Fluxo:
#   1. Fotografa a imagem atual em execução (OLD_IMAGE)
#   2. Faz pull da nova imagem
#   3. Para o container antigo
#   4. Sobe o container com a nova imagem
#   5. Realiza health check
#      → Sucesso: encerra normalmente
#      → Falha:   derruba a versão nova e restaura OLD_IMAGE
# ============================================================

set -uo pipefail

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/petersonwa/devops-fase1}"
TAG="${TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-devops-app}"
PORT="${PORT:-3000}"
HEALTH_CHECK_RETRIES=5
HEALTH_CHECK_INTERVAL=3

echo "============================================"
echo "  DEPLOY COM AUTO-ROLLBACK - DevOps Fase 2"
echo "============================================"
echo "Imagem    : $IMAGE_NAME:$TAG"
echo "Container : $CONTAINER_NAME"
echo "Porta     : $PORT"
echo "Ambiente  : ${NODE_ENV:-production}"
echo "============================================"

# ── PASSO 1: Fotografar a versão atual em execução ──────────
echo ""
echo "[1/5] Verificando versão atual em execução..."
OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo "")

if [ -n "$OLD_IMAGE" ]; then
  echo "      Versão atual: $OLD_IMAGE (salva para rollback automático)"
else
  echo "      Nenhum container anterior (primeiro deploy)."
fi

# ── PASSO 2: Pull da nova imagem ────────────────────────────
echo ""
echo "[2/5] Baixando nova imagem Docker..."
docker pull "$IMAGE_NAME:$TAG"
echo "      Imagem baixada com sucesso."

# ── PASSO 3: Para o container atual ─────────────────────────
echo ""
echo "[3/5] Parando container atual..."
if docker ps -q --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
  echo "      Container anterior removido."
else
  echo "      Nenhum container em execução para remover."
fi

# ── PASSO 4: Sobe o novo container ──────────────────────────
echo ""
echo "[4/5] Iniciando nova versão ($IMAGE_NAME:$TAG)..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$PORT:3000" \
  -e NODE_ENV="${NODE_ENV:-production}" \
  -e APP_VERSION="$TAG" \
  "$IMAGE_NAME:$TAG"
echo "      Container '$CONTAINER_NAME' iniciado."

# ── PASSO 5: Health check com decisão automática ────────────
echo ""
echo "[5/5] Verificando saúde da nova versão..."
HEALTH_OK=false

for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
  sleep $HEALTH_CHECK_INTERVAL
  if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
    HEALTH_OK=true
    echo "      Health check OK (tentativa $i/$HEALTH_CHECK_RETRIES)"
    break
  fi
  echo "      Aguardando... (tentativa $i/$HEALTH_CHECK_RETRIES)"
done

# ── DECISÃO: Sucesso ou Rollback Automático ──────────────────
if [ "$HEALTH_OK" = true ]; then
  echo ""
  echo "============================================"
  echo "  DEPLOY CONCLUIDO COM SUCESSO!"
  echo "  Versao ativa: $IMAGE_NAME:$TAG"
  echo "  URL: http://localhost:$PORT"
  echo "============================================"
  exit 0
fi

# Health check falhou → aciona rollback automático
echo ""
echo "============================================"
echo "  HEALTH CHECK FALHOU! Rollback automatico."
echo "============================================"
echo "  Derrubando versao com falha..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm   "$CONTAINER_NAME" 2>/dev/null || true

if [ -n "$OLD_IMAGE" ]; then
  echo "  Restaurando versao anterior: $OLD_IMAGE"
  docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$PORT:3000" \
    -e NODE_ENV="${NODE_ENV:-production}" \
    "$OLD_IMAGE"
  echo ""
  echo "  ROLLBACK AUTOMATICO CONCLUIDO."
  echo "  Servico restaurado: $OLD_IMAGE"
  echo "  URL: http://localhost:$PORT"
else
  echo "  Nenhuma versao anterior disponivel."
  echo "  Servico esta fora do ar. Intervencao manual necessaria."
fi

echo "============================================"
exit 1