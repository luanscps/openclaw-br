#!/bin/bash
# =============================================================================
# setup-agents.sh — Cria e configura os 4 agentes OpenClaw com IAs gratuitas
# =============================================================================
# Agentes criados:
#   geral    → groq/llama-3.3-70b-versatile   (uso geral, padrão)
#   coder    → groq/gemma2-9b-it              (especialista em código)
#   pesquisa → groq/mixtral-8x7b-32768        (análise e pesquisa profunda)
#   familia  → groq/llama-3.1-8b-instant      (grupo familiar, restrito)
# =============================================================================

set -euo pipefail

CONTAINER="openclaw-gateway"
BASE_DIR="/DATA/AppData/openclaw"
CONFIG_DIR="${BASE_DIR}/config"  # mapeado para /data/.openclaw no container

echo "================================================="
echo " 🦞 OpenClaw — Setup Multi-Agente"
echo "================================================="

# Verificar se o container está rodando
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌ Container '${CONTAINER}' não está rodando."
  echo "   Execute: docker compose up -d"
  exit 1
fi

echo ""
echo "▶ Criando agentes via CLI..."

# Criar agentes (o wizard cria workspace + SOUL.md padrão + agentDir)
docker exec "${CONTAINER}" openclaw agents add geral    2>/dev/null || echo "  (geral já existe)"
docker exec "${CONTAINER}" openclaw agents add coder    2>/dev/null || echo "  (coder já existe)"
docker exec "${CONTAINER}" openclaw agents add pesquisa 2>/dev/null || echo "  (pesquisa já existe)"
docker exec "${CONTAINER}" openclaw agents add familia  2>/dev/null || echo "  (familia já existe)"

echo ""
echo "▶ Copiando SOUL.md personalizados para cada workspace..."

# Caminhos dos workspaces dentro do container (HOME=/data → ~/.openclaw=/data/.openclaw)
for AGENT in geral coder pesquisa familia; do
  WORKSPACE_HOST="${CONFIG_DIR}/workspace-${AGENT}"
  mkdir -p "${WORKSPACE_HOST}"

  if [ -f "$(dirname "$0")/agents/${AGENT}/SOUL.md" ]; then
    cp "$(dirname "$0")/agents/${AGENT}/SOUL.md" "${WORKSPACE_HOST}/SOUL.md"
    echo "  ✅ ${AGENT}/SOUL.md copiado"
  else
    echo "  ⚠️  agents/${AGENT}/SOUL.md não encontrado — pulando"
  fi
done

echo ""
echo "▶ Configurando modelos por agente..."

docker exec "${CONTAINER}" openclaw config set agents.list.geral.model    groq/llama-3.3-70b-versatile
docker exec "${CONTAINER}" openclaw config set agents.list.coder.model    groq/gemma2-9b-it
docker exec "${CONTAINER}" openclaw config set agents.list.pesquisa.model groq/mixtral-8x7b-32768
docker exec "${CONTAINER}" openclaw config set agents.list.familia.model  groq/llama-3.1-8b-instant

echo "  ✅ Modelos configurados"

echo ""
echo "▶ Definindo agente 'geral' como padrão..."
docker exec "${CONTAINER}" openclaw config set agents.defaults.id geral
echo "  ✅ Padrão: geral"

echo ""
echo "▶ Reiniciando gateway para aplicar configurações..."
docker restart "${CONTAINER}"
echo "  ✅ Restart iniciado — aguarde ~10 segundos"

sleep 10

echo ""
echo "▶ Verificando agentes criados:"
docker exec "${CONTAINER}" openclaw agents list --bindings

echo ""
echo "================================================="
echo " ✅ Setup completo! Acesse https://10.41.10.153"
echo ""
echo " Agentes disponíveis:"
echo "   @geral    → Llama 3.3 70B  (uso geral)"
echo "   @coder    → Gemma 2 9B     (código)"
echo "   @pesquisa → Mixtral 8x7B   (análise)"
echo "   @familia  → Llama 3.1 8B   (grupo familiar)"
echo "================================================="
