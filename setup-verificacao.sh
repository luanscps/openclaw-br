#!/bin/bash

# ==============================================
# OpenClaw - Script de Verificação e Deploy
# Adaptado para CasaOS + Portainer + macvlan-dhcp
# ==============================================

set -e

echo "🦞 OpenClaw - Verificação e Deploy"
echo "===================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Verificar estrutura de diretórios
echo -e "${BLUE}[1/5] Verificando estrutura de diretórios...${NC}"
if [ ! -d "/DATA/AppData/openclaw" ]; then
    echo -e "${YELLOW}  ⚠️  Diretório não existe. Criando...${NC}"
    mkdir -p /DATA/AppData/openclaw/{config,workspace,credentials,cache}
    sudo chown -R 1000:1000 /DATA/AppData/openclaw/
    echo -e "${GREEN}  ✅ Diretório criado em /DATA/AppData/openclaw${NC}"
else
    echo -e "${GREEN}  ✅ Diretório já existe${NC}"
fi
echo ""

# 2. Verificar arquivo docker-compose.yml
echo -e "${BLUE}[2/5] Verificando docker-compose.yml...${NC}"
if [ ! -f "/DATA/AppData/openclaw/docker-compose.yml" ]; then
    echo -e "${YELLOW}  ⚠️  docker-compose.yml não encontrado.${NC}"
    echo -e "${YELLOW}  📏 Copie o arquivo docker-compose.yml para /DATA/AppData/openclaw/${NC}"
    exit 1
else
    echo -e "${GREEN}  ✅ docker-compose.yml encontrado${NC}"
    echo -e "${BLUE}    Serviços configurados:${NC}"
    grep "container_name:" /DATA/AppData/openclaw/docker-compose.yml | sed 's/^/      /'
fi
echo ""

# 3. Verificar arquivo .env
echo -e "${BLUE}[3/5] Verificando arquivo .env...${NC}"
if [ ! -f "/DATA/AppData/openclaw/.env" ]; then
    echo -e "${YELLOW}  ⚠️  .env não encontrado. Criando de .env.example...${NC}"
    if [ -f "/DATA/AppData/openclaw/.env.example" ]; then
        cp /DATA/AppData/openclaw/.env.example /DATA/AppData/openclaw/.env
        echo -e "${YELLOW}  📏 IMPORTANTE: Edite /DATA/AppData/openclaw/.env com suas credenciais${NC}"
        echo -e "${YELLOW}     nano /DATA/AppData/openclaw/.env${NC}"
    else
        echo -e "${RED}  ❌ Nem .env nem .env.example encontrados${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✅ .env encontrado${NC}"
    # Verificar se tem credenciais
    if grep -q "XXXXXXXXXXXXXXXXXXXXX" /DATA/AppData/openclaw/.env; then
        echo -e "${YELLOW}  ⚠️  ATENÇÃO: .env contém valores de exemplo${NC}"
        echo -e "${YELLOW}  📏 Edite com suas credenciais reais:${NC}"
        echo -e "${YELLOW}     nano /DATA/AppData/openclaw/.env${NC}"
    else
        echo -e "${GREEN}  ✅ Credenciais parecem configuradas${NC}"
    fi
fi
echo ""

# 4. Verificar rede macvlan-dhcp
echo -e "${BLUE}[4/5] Verificando rede Docker macvlan-dhcp...${NC}"
if docker network ls | grep -q "macvlan-dhcp"; then
    echo -e "${GREEN}  ✅ Rede macvlan-dhcp encontrada${NC}"
    echo -e "${BLUE}    Detalhes:${NC}"
    docker network inspect macvlan-dhcp | grep -E '"Name"|"Subnet"|"Gateway"|"IPRange"' | sed 's/^/      /'
else
    echo -e "${RED}  ❌ Rede macvlan-dhcp NÃO encontrada${NC}"
    echo -e "${YELLOW}  📏 Crie em Portainer > Networks > Create network${NC}"
    exit 1
fi
echo ""

# 5. Verificar Docker e Docker Compose
echo -e "${BLUE}[5/5] Verificando Docker e Docker Compose...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}  ❌ Docker não está instalado${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Docker: $(docker --version)${NC}"

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}  ❌ Docker Compose não está instalado${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Docker Compose: $(docker-compose --version)${NC}"
echo ""

# Resumo e próximos passos
echo "===================================="
echo -e "${GREEN}✅ Verificação completa!${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "1. Edite o arquivo .env com suas credenciais:"
echo -e "${BLUE}   nano /DATA/AppData/openclaw/.env${NC}"
echo ""
echo "2. Deploy via Portainer (Recomendado):"
echo -e "${BLUE}   - Acesse: http://10.0.110.132:9001${NC}"
echo -e "${BLUE}   - Stacks > Add stack${NC}"
echo -e "${BLUE}   - Cole o conteúdo de docker-compose.yml${NC}"
echo ""
echo "3. OU deploy via Docker Compose:"
echo -e "${BLUE}   cd /DATA/AppData/openclaw${NC}"
echo -e "${BLUE}   docker-compose up -d${NC}"
echo ""
echo "4. Acesse a UI (SSH Tunnel):"
echo -e "${BLUE}   ssh -N -L 18789:10.41.10.151:18789 seu-usuario@seu-servidor.local${NC}"
echo -e "${BLUE}   Navegador: http://127.0.0.1:18789${NC}"
echo ""
echo -e "${YELLOW}⚠️  INFORMAÇÕES IMPORTANTES:${NC}"
echo "   • IP alocado: 10.41.10.151"
echo "   • Porta: 18789"
echo "   • Dados em: /DATA/AppData/openclaw/"
echo "   • Logs: docker logs openclaw-gateway"
echo ""
