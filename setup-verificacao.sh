#!/bin/bash

# ==============================================
# OpenClaw - Script de Verificação e Deploy
# Adaptado para CasaOS + Portainer + macvlan-dhcp
# IP: 10.41.10.153 | Porta: 8080
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
NC='\033[0m'

# 1. Verificar estrutura de diretórios
echo -e "${BLUE}[1/6] Verificando estrutura de diretórios...${NC}"
DIRS=("config" "workspace" "browser-profile")
for dir in "${DIRS[@]}"; do
    if [ ! -d "/DATA/AppData/openclaw/$dir" ]; then
        echo -e "${YELLOW}  ⚠️  Criando diretório: $dir${NC}"
        mkdir -p "/DATA/AppData/openclaw/$dir"
    else
        echo -e "${GREEN}  ✅ $dir${NC}"
    fi
done
sudo chown -R 1000:1000 /DATA/AppData/openclaw/
echo -e "${GREEN}  ✅ Permissões ajustadas (1000:1000)${NC}"
echo ""

# 2. Verificar arquivo docker-compose.yml
echo -e "${BLUE}[2/6] Verificando docker-compose.yml...${NC}"
if [ ! -f "/DATA/AppData/openclaw/docker-compose.yml" ]; then
    echo -e "${RED}  ❌ docker-compose.yml não encontrado.${NC}"
    echo -e "${YELLOW}  📏 Copie o arquivo para /DATA/AppData/openclaw/${NC}"
    exit 1
else
    echo -e "${GREEN}  ✅ docker-compose.yml encontrado${NC}"
    echo -e "${BLUE}    Serviços configurados:${NC}"
    grep "container_name:" /DATA/AppData/openclaw/docker-compose.yml | sed 's/^/      /'
    # Verificar se usa a imagem correta
    if grep -q "coollabsio/openclaw" /DATA/AppData/openclaw/docker-compose.yml; then
        echo -e "${GREEN}  ✅ Imagem: coollabsio/openclaw:latest${NC}"
    else
        echo -e "${RED}  ❌ Imagem incorreta! Deve ser coollabsio/openclaw:latest${NC}"
    fi
    # Verificar browser sidecar
    if grep -q "kasmweb/chrome" /DATA/AppData/openclaw/docker-compose.yml; then
        echo -e "${GREEN}  ✅ Browser sidecar configurado${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Browser sidecar não encontrado no compose${NC}"
    fi
fi
echo ""

# 3. Verificar arquivo .env
echo -e "${BLUE}[3/6] Verificando arquivo .env...${NC}"
if [ ! -f "/DATA/AppData/openclaw/.env" ]; then
    echo -e "${YELLOW}  ⚠️  .env não encontrado. Criando de .env.example...${NC}"
    if [ -f "/DATA/AppData/openclaw/.env.example" ]; then
        cp /DATA/AppData/openclaw/.env.example /DATA/AppData/openclaw/.env
        echo -e "${YELLOW}  📏 IMPORTANTE: Edite o .env com suas credenciais:${NC}"
        echo -e "${YELLOW}     nano /DATA/AppData/openclaw/.env${NC}"
    else
        echo -e "${RED}  ❌ Nem .env nem .env.example encontrados${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✅ .env encontrado${NC}"
    if grep -q "XXXXXXXXXXXXXXXXXXXXX\|sua_senha_forte\|seu_token_super" /DATA/AppData/openclaw/.env; then
        echo -e "${YELLOW}  ⚠️  ATENÇÃO: .env ainda contém valores de exemplo!${NC}"
        echo -e "${YELLOW}  📏 Edite com suas credenciais reais:${NC}"
        echo -e "${YELLOW}     nano /DATA/AppData/openclaw/.env${NC}"
    else
        echo -e "${GREEN}  ✅ Credenciais parecem configuradas${NC}"
    fi
    # Verificar AUTH_PASSWORD
    if grep -q "^AUTH_PASSWORD=" /DATA/AppData/openclaw/.env; then
        echo -e "${GREEN}  ✅ AUTH_PASSWORD definido${NC}"
    else
        echo -e "${RED}  ❌ AUTH_PASSWORD não encontrado no .env (obrigatório)${NC}"
    fi
fi
echo ""

# 4. Verificar rede macvlan-dhcp
echo -e "${BLUE}[4/6] Verificando rede Docker macvlan-dhcp...${NC}"
if docker network ls | grep -q "macvlan-dhcp"; then
    echo -e "${GREEN}  ✅ Rede macvlan-dhcp encontrada${NC}"
    docker network inspect macvlan-dhcp | grep -E '"Name"|"Subnet"|"Gateway"|"IPRange"' | sed 's/^/      /'
else
    echo -e "${RED}  ❌ Rede macvlan-dhcp NÃO encontrada${NC}"
    echo -e "${YELLOW}  📏 Crie em Portainer > Networks > Create network (macvlan)${NC}"
    exit 1
fi
echo ""

# 5. Verificar IP 10.41.10.153 disponível
echo -e "${BLUE}[5/6] Verificando disponibilidade do IP 10.41.10.153...${NC}"
if ping -c 1 -W 1 10.41.10.153 &>/dev/null; then
    echo -e "${YELLOW}  ⚠️  IP 10.41.10.153 está respondendo (pode já estar em uso)${NC}"
else
    echo -e "${GREEN}  ✅ IP 10.41.10.153 disponível${NC}"
fi
echo ""

# 6. Verificar Docker e Docker Compose
echo -e "${BLUE}[6/6] Verificando Docker e Docker Compose...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}  ❌ Docker não está instalado${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Docker: $(docker --version)${NC}"

if docker compose version &> /dev/null; then
    echo -e "${GREEN}  ✅ Docker Compose: $(docker compose version)${NC}"
elif command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}  ✅ Docker Compose (legado): $(docker-compose --version)${NC}"
else
    echo -e "${RED}  ❌ Docker Compose não está instalado${NC}"
    exit 1
fi
echo ""

# Resumo e próximos passos
echo "===================================="
echo -e "${GREEN}✅ Verificação completa!${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo ""
echo "1. Edite o arquivo .env com suas credenciais:"
echo -e "${BLUE}   nano /DATA/AppData/openclaw/.env${NC}"
echo ""
echo "2. Deploy via Portainer (Recomendado):"
echo -e "${BLUE}   - Acesse: http://10.0.110.132:9001${NC}"
echo -e "${BLUE}   - Stacks > Add stack > Cole o conteúdo de docker-compose.yml${NC}"
echo -e "${BLUE}   - Adicione as variáveis do .env em 'Environment variables'${NC}"
echo -e "${BLUE}   - Clique em Deploy${NC}"
echo ""
echo "3. OU deploy via terminal:"
echo -e "${BLUE}   cd /DATA/AppData/openclaw${NC}"
echo -e "${BLUE}   docker compose up -d${NC}"
echo ""
echo "4. Acesse a UI diretamente na rede local:"
echo -e "${BLUE}   http://10.41.10.153:8080${NC}"
echo -e "${BLUE}   Login: admin / (sua AUTH_PASSWORD)${NC}"
echo ""
echo "5. Verificar containers após deploy:"
echo -e "${BLUE}   docker ps | grep openclaw${NC}"
echo -e "${BLUE}   docker logs -f openclaw-gateway${NC}"
echo ""
echo -e "${YELLOW}⚠️  INFORMAÇÕES DO AMBIENTE:${NC}"
echo "   • IP alocado:         10.41.10.153"
echo "   • Porta UI (nginx):   8080"
echo "   • Gateway (interno):  18789"
echo "   • Imagem principal:   coollabsio/openclaw:latest"
echo "   • Imagem browser:     kasmweb/chrome:1.16.0"
echo "   • Dados em:           /DATA/AppData/openclaw/"
echo "   • Logs:               docker logs openclaw-gateway"
echo ""
