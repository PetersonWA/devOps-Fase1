#!/bin/bash
# ============================================================
# Script de Rollback Manual - DevOps Fase 2
#
# QUANDO USAR:
#   Este script é uma válvula de escape para situações onde
#   o deploy.sh considerou o deploy bem-sucedido (health check
#   passou), mas horas depois a equipe detectou um problema de
#   lógica de negócio ou regressão que o /health não captura.
#
#   Para falhas técnicas imediatas (crash, porta indisponível),
#   o próprio deploy.sh já faz rollback automático.
#
# USO:
#   PREVIOUS_TAG=sha-abc1234 bash scripts/rollback.sh
# ============================================================

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/petersonwa/devops-fase1}"
PREVIOUS_TAG="${PREVIOUS_TAG:-}"
CONTAINER_NAME="${CONTAINER_NAME:-devops-app}"
PORT="${PORT:-3000}"

echo "============================================"
echo "  ROLLBACK MANUAL - DevOps Fase 2"
echo "============================================"

if [ -z "$PREVIOUS_TAG" ]; then
  echo "ERRO: Informe a tag da versao anterior."
  echo ""
  echo "Uso: PREVIOUS_TAG=sha-abc1234 bash scripts/rollback.sh"
  echo ""
  echo "Para ver as tags disponiveis:"
  echo "  docker images ghcr.io/petersonwa/devops-fase1"
  exit 1
fi

echo "Revertendo para: $IMAGE_NAME:$PREVIOUS_TAG"
echo "============================================"

# 1. Registra a versão que está sendo revertida
CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo "desconhecida")
echo ""
echo "[1/3] Versao atual (sera revertida): $CURRENT_IMAGE"

# 2. Para o container atual e sobe a versão anterior
echo ""
echo "[2/3] Substituindo container..."
if docker ps -q --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
fi

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$PORT:3000" \
  -e NODE_ENV="${NODE_ENV:-production}" \
  -e APP_VERSION="$PREVIOUS_TAG" \
  "$IMAGE_NAME:$PREVIOUS_TAG"

# 3. Confirma que o serviço respondeu
echo ""
echo "[3/3] Verificando servico apos rollback..."
sleep 5
if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
  echo "      Servico respondendo normalmente."
else
  echo "      AVISO: Servico pode ainda estar inicializando."
  echo "      Verifique: docker logs $CONTAINER_NAME"
fi

echo ""
echo "============================================"
echo "  ROLLBACK MANUAL CONCLUIDO."
echo "  Versao revertida : $CURRENT_IMAGE"
echo "  Versao ativa     : $IMAGE_NAME:$PREVIOUS_TAG"
echo "  URL: http://localhost:$PORT"
echo "============================================"