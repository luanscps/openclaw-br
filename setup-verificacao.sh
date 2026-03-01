#!/bin/bash
# =============================================================================
# OpenClaw BR — Script de verificação e setup
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC}  $1"; }

echo ""
echo "====================================================="
echo "   OpenClaw BR — Verificação do ambiente"
echo "====================================================="
echo ""

# 1. Docker
log "Verificando Docker..."
if command -v docker &>/dev/null; then
    ok "Docker instalado: $(docker --version)"
else
    err "Docker não encontrado. Instale antes de continuar."
    exit 1
fi

# 2. Docker Compose
log "Verificando Docker Compose..."
if docker compose version &>/dev/null 2>&1; then
    ok "Docker Compose: $(docker compose version)"
else
    err "Docker Compose plugin não encontrado."
    exit 1
fi

# 3. Arquivo .env
log "Verificando .env..."
if [ ! -f .env ]; then
    warn ".env não encontrado. Copiando de .env.example..."
    cp .env.example .env
    warn "Edite o arquivo .env com suas chaves antes de subir."
else
    ok ".env encontrado."
fi

# 4. Diretórios de dados
log "Criando diretórios de dados..."
DIRS=(
    "/DATA/AppData/openclaw/config"
    "/DATA/AppData/openclaw/workspace"
    "/DATA/AppData/openclaw/caddy-data"
    "/DATA/AppData/openclaw/caddy-config"
)
for d in "${DIRS[@]}"; do
    mkdir -p "$d"
    ok "Diretório: $d"
done

# 5. Caddyfile
log "Verificando Caddyfile..."
if [ ! -f /DATA/AppData/openclaw/Caddyfile ]; then
    if [ -f ./Caddyfile ]; then
        cp ./Caddyfile /DATA/AppData/openclaw/Caddyfile
        ok "Caddyfile copiado para /DATA/AppData/openclaw/Caddyfile"
    else
        err "Caddyfile não encontrado no repositório."
        exit 1
    fi
else
    ok "Caddyfile já existe."
fi

# 6. Rede macvlan
log "Verificando rede macvlan-dhcp..."
if docker network ls | grep -q macvlan-dhcp; then
    ok "Rede macvlan-dhcp encontrada."
else
    warn "Rede macvlan-dhcp não existe. Crie antes de subir:"
    warn "  docker network create -d macvlan --subnet=10.41.10.0/24 \\"
    warn "    --gateway=10.41.10.1 -o parent=eth0 macvlan-dhcp"
fi

echo ""
echo "====================================================="
ok "Verificação concluída!"
echo ""
echo "  Próximo passo:"
echo "    docker compose up -d"
echo "    docker compose logs -f"
echo ""
echo "  Acesse: https://10.41.10.153"
echo "  (Aceite o certificado autoassinado no primeiro acesso)"
echo "====================================================="
echo ""
