# 🦞 OpenClaw Brasil — Docker + CasaOS + Portainer + macvlan-dhcp

> Assistente de IA Pessoal rodando em sua infraestrutura própria

[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/issues)

## Visão Geral

Este repositório contém a instalação otimizada do [OpenClaw](https://github.com/openclaw/openclaw) para ambientes CasaOS com Docker, Portainer e rede **macvlan-dhcp** já configurada.

🎯 **Objetivo:** Deploy pronto em ~20 minutos utilizando exatamente sua infraestrutura existente

## Infraestrutura Necessária

```
┌─────────────────────────────────────────────────┐
│     VM: Ubuntu + Docker + Portainer + CasaOS    │
├─────────────────────────────────────────────────┤
│ Rede: macvlan-dhcp (10.41.10.0/24)             │
│ Gateway: 10.41.10.1                            │
│ Range IP: 10.41.10.128/25                      │
│ Armazenamento: /DATA/AppData/                  │
└─────────────────────────────────────────────────┘
```

### Pré-Requisitos

- ✅ Docker 20.10+
- ✅ Docker Compose v2+
- ✅ Portainer 2.15+ (opcional)
- ✅ Rede **macvlan-dhcp** já criada
- ✅ API Key do Anthropic (Claude) ou OpenAI (GPT)
- ✅ SSH acesso ao servidor

## Arquitetura

| Componente | Especificação |
|-----------|---------------|
| **Container** | openclaw-gateway |
| **Imagem** | openclaw:latest |
| **IP Alocado** | 10.41.10.151/24 |
| **Porta** | 18789 |
| **Diretório** | /DATA/AppData/openclaw/ |
| **Rede** | macvlan-dhcp (external) |
| **Restart** | unless-stopped |

## Estrutura de Arquivos

```
openclaw-br/
├── docker-compose.yml          # Stack pronto para Portainer
├── .env.example                # Template de variáveis de ambiente
├── setup-verificacao.sh        # Script automático de validação
├── README.md                   # Este arquivo
├── LICENSE                     # MIT License
└── docs/
    ├── INSTALACAO_PASSO_A_PASSO.md
    ├── CONFIGURACAO_CANAIS.md
    ├── TROUBLESHOOTING.md
    └── BACKUP_RESTAURACAO.md
```

## Quickstart (20 minutos)

### 1️⃣ Clonar o Repositório

```bash
cd /DATA/AppData
git clone https://github.com/luanscps/openclaw-br.git openclaw
cd openclaw
```

### 2️⃣ Preparar Estrutura

```bash
# Criar diretórios de dados
mkdir -p config workspace credentials cache

# Definir permissões
sudo chown -R 1000:1000 .
chmod +x setup-verificacao.sh
```

### 3️⃣ Executar Verificação

```bash
./setup-verificacao.sh
```

**Esperado:** Todos os checkes em ✅

### 4️⃣ Configurar Credenciais

```bash
# Copiar template
cp .env.example .env

# Editar com suas chaves reais
nano .env
```

Substituir:
- `sk-ant-XXXXXXXXXXXXXXXXXXXXX` → Sua chave [Anthropic Console](https://console.anthropic.com/)
- `seu_token_super_seguro_aqui_32_chars` → (gerado automaticamente)

### 5️⃣ Deploy

**Opção A: Via Portainer UI (Recomendado)**

1. Acesse http://10.0.110.132:9001
2. **Stacks** → **Add stack**
3. Nome: `openclaw`
4. Cole o conteúdo de `docker-compose.yml`
5. **Deploy**

**Opção B: Via Docker Compose**

```bash
docker-compose up -d
```

### 6️⃣ Acessar a UI

**Do seu laptop:**

```bash
# Terminal 1: SSH Tunnel
ssh -N -L 18789:10.41.10.151:18789 seu-usuario@seu-servidor.local

# Terminal 2: Navegador
open http://127.0.0.1:18789
```

Cole o token do `.env` para autenticar.

## Configuração Detalhada

### Variáveis de Ambiente (.env)

| Variável | Descrição | Obrigatório |
|----------|-----------|-------------|
| `ANTHROPIC_API_KEY` | Chave do Claude (Anthropic) | Sim (ou OpenAI) |
| `OPENAI_API_KEY` | Chave do GPT-4o (OpenAI) | Alternativa |
| `OPENCLAW_GATEWAY_TOKEN` | Token seguro do gateway | Sim |
| `TELEGRAM_BOT_TOKEN` | Token do bot Telegram | Não |
| `DISCORD_BOT_TOKEN` | Token do bot Discord | Não |

### Volumes Mapeados

```yaml
/DATA/AppData/openclaw/config       → ~/.openclaw
/DATA/AppData/openclaw/workspace    → ~/.openclaw/workspace
/DATA/AppData/openclaw/credentials  → ~/.openclaw/credentials
/DATA/AppData/openclaw/cache        → ~/.openclaw/cache
```

Todos os dados são **persistentes** entre restarts.

## Operações Comuns

### Ver Status

```bash
docker compose ps
```

### Ver Logs

```bash
# Tempo real
docker compose logs -f openclaw-gateway

# Últimas linhas
docker compose logs --tail 50
```

### Parar / Reiniciar

```bash
# Parar
docker compose down

# Reiniciar
docker compose restart

# Recriar com nova imagem
docker compose pull
docker compose up -d --force-recreate
```

### Backup

```bash
# Comprimir dados
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz .

# Restaurar
tar -xzf ~/openclaw-backup-20260201.tar.gz -C /DATA/AppData/openclaw/
```

## Integração com Canais

### WhatsApp

```bash
docker exec openclaw-gateway openclaw channels login
# Escaneia QR code com celular
```

### Telegram

```bash
docker exec openclaw-gateway openclaw channels add --channel telegram --token "seu-bot-token"
```

### Discord

```bash
docker exec openclaw-gateway openclaw channels add --channel discord --token "seu-bot-token"
```

## Troubleshooting

### Container não inicia

```bash
docker logs openclaw-gateway
```

Procure por erros de API key ou configuração.

### Não consegue acessar UI

```bash
# Verifique SSH tunnel
ps aux | grep "18789:10.41.10.151"

# Teste conectividade
curl http://10.41.10.151:18789/health
```

### Permissões de arquivo

```bash
sudo chown -R 1000:1000 /DATA/AppData/openclaw/
```

Ver [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) para mais soluções.

## Documentação Adicional

- 📖 [Instalação Passo a Passo](docs/INSTALACAO_PASSO_A_PASSO.md)
- 🔧 [Configuração de Canais](docs/CONFIGURACAO_CANAIS.md)
- 🐛 [Troubleshooting](docs/TROUBLESHOOTING.md)
- 💾 [Backup e Restauração](docs/BACKUP_RESTAURACAO.md)

## Stack Complementar

Seu OpenClaw agora faz parte do ecossistema CasaOS/Portainer:

| Serviço | IP | Porta | Uso |
|---------|-----|-------|-----|
| Portainer | 10.0.110.132 | 9001 | Gerenciamento |
| Caddy | 10.41.10.128 | 80/443 | Proxy reverso |
| Prometheus | 10.41.10.140 | 9090 | Monitoramento |
| OpenClaw | 10.41.10.151 | 18789 | IA Pessoal |

## Segurança

🔐 **Boas Práticas:**

- ✅ Use SSH tunnel para acesso remoto (não exponha porta direto)
- ✅ Gere token forte: `openssl rand -hex 32`
- ✅ API keys nunca aparecem em logs
- ✅ Dados isolados em volumes Docker
- ✅ Firewall ativo na VM
- ✅ Backups regulares em `/DATA/Backups/`

## Performance

**Requisitos Mínimos:**
- CPU: 2 cores
- RAM: 4GB
- Disco: 20GB

**Recomendado:**
- CPU: 4+ cores
- RAM: 8GB+
- Disco: 50GB+

## Licença

MIT License — veja [LICENSE](LICENSE)

## Contribuições

Contribuições são bem-vindas! Abra uma issue ou pull request.

## Referências

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Portainer Documentation](https://docs.portainer.io/)

## Suporte

💬 Dúvidas ou sugestões?

- Abra uma [Issue](https://github.com/luanscps/openclaw-br/issues)
- Consulte a [Discussão](https://github.com/luanscps/openclaw-br/discussions)
- Veja [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

**Criado por:** [luanscps](https://github.com/luanscps)  
**Última atualização:** Fevereiro 2026  
**Status:** ✅ Pronto para produção
