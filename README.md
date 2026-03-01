# 🦞 OpenClaw Brasil — Docker + CasaOS + Portainer + macvlan-dhcp

> Assistente de IA Pessoal rodando em sua infraestrutura própria

[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/issues)

## Visão Geral

Este repositório contém a instalação otimizada do [OpenClaw](https://github.com/openclaw/openclaw) para ambientes CasaOS com Docker, Portainer e rede **macvlan-dhcp** já configurada.

> **Imagem utilizada:** [`coollabsio/openclaw:latest`](https://github.com/coollabsio/openclaw) — imagem pré-compilada, atualizada automaticamente a cada 6h, com nginx + browser sidecar incluídos.

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
| **Container principal** | openclaw-gateway |
| **Imagem** | coollabsio/openclaw:latest |
| **IP Alocado** | 10.41.10.153/24 |
| **Porta UI (nginx)** | 8080 |
| **Porta Gateway (interno)** | 18789 |
| **Container browser** | openclaw-browser |
| **Imagem browser** | kasmweb/chrome:1.16.0 |
| **Diretório** | /DATA/AppData/openclaw/ |
| **Rede externa** | macvlan-dhcp |
| **Rede interna** | openclaw-internal (bridge) |
| **Restart** | unless-stopped |

### Diagrama de Rede

```
Sua rede local (macvlan-dhcp)
         │
         ▼  http://10.41.10.153:8080
┌──────────────────────────────────────────┐
│  openclaw-gateway (coollabsio/openclaw)  │
│  nginx :8080  ──▶  gateway :18789        │
│  Login: admin / AUTH_PASSWORD            │
└────────────┬─────────────────────────────┘
             │ openclaw-internal (bridge)
             ▼  http://browser:9222 (CDP)
    ┌────────────────────┐
    │  openclaw-browser  │
    │  kasmweb/chrome    │
    │  Chrome CDP :9222  │
    └────────────────────┘
      (sem IP externo —
       isolado na rede
       interna)
```

## Estrutura de Arquivos

```
openclaw-br/
├── docker-compose.yml          # Stack com gateway + browser sidecar
├── .env.example                # Template de variáveis de ambiente
├── setup-verificacao.sh        # Script automático de validação
├── README.md                   # Este arquivo
└── LICENSE                     # MIT License
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
mkdir -p config workspace browser-profile

# Definir permissões
sudo chown -R 1000:1000 .
chmod +x setup-verificacao.sh
```

### 3️⃣ Executar Verificação

```bash
./setup-verificacao.sh
```

**Esperado:** Todos os checks em ✅

### 4️⃣ Configurar Credenciais

```bash
# Copiar template
cp .env.example .env

# Editar com suas chaves reais
nano .env
```

Substituir:
- `sk-ant-XXXXXXXXXXXXXXXXXXXXX` → Sua chave [Anthropic Console](https://console.anthropic.com/)
- `seu_token_super_seguro_aqui_32_chars` → Gere com `openssl rand -hex 32`
- `sua_senha_forte_aqui` → Senha para login na UI (gere com `openssl rand -base64 16`)

### 5️⃣ Deploy

**Opção A: Via Portainer UI (Recomendado)**

1. Acesse http://10.0.110.132:9001
2. **Stacks** → **Add stack**
3. Nome: `openclaw`
4. Cole o conteúdo de `docker-compose.yml`
5. Na seção **Environment variables**, adicione as variáveis do `.env`
6. Clique em **Deploy the stack**

**Opção B: Via Docker Compose**

```bash
docker compose up -d
```

### 6️⃣ Acessar a UI

Acesse diretamente na sua rede local:

```
http://10.41.10.153:8080
```

Login: `admin` / senha definida em `AUTH_PASSWORD` do `.env`

> **Acesso remoto (fora da rede local):** Use SSH tunnel:
> ```bash
> ssh -N -L 8080:10.41.10.153:8080 seu-usuario@seu-servidor.local
> # Acesse: http://127.0.0.1:8080
> ```

## Configuração Detalhada

### Variáveis de Ambiente (.env)

| Variável | Descrição | Obrigatório |
|----------|-----------|-------------|
| `ANTHROPIC_API_KEY` | Chave do Claude (Anthropic) | Sim (ou OpenAI) |
| `OPENAI_API_KEY` | Chave do GPT-4o (OpenAI) | Alternativa |
| `OPENCLAW_GATEWAY_TOKEN` | Token seguro do gateway | Sim |
| `AUTH_PASSWORD` | Senha da interface web (nginx) | **Sim** |
| `TELEGRAM_BOT_TOKEN` | Token do bot Telegram | Não |
| `DISCORD_BOT_TOKEN` | Token do bot Discord | Não |

### Volumes Mapeados

```yaml
/DATA/AppData/openclaw/config          → /data/.openclaw
/DATA/AppData/openclaw/workspace       → /data/workspace
/DATA/AppData/openclaw/browser-profile → /home/kasm-user  (browser)
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

# Logs do browser sidecar
docker logs -f openclaw-browser
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
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz config workspace

# Restaurar
tar -xzf ~/openclaw-backup-XXXXXXXX.tar.gz -C /DATA/AppData/openclaw/
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

### Erro: host not found in upstream "browser"

```
[emerg] host not found in upstream "browser" in /etc/nginx/conf.d/openclaw.conf
```

O nginx espera o container `browser` rodando na mesma rede interna. Verifique:

```bash
docker ps | grep openclaw-browser
```

Se não estiver rodando, garanta que o `docker-compose.yml` contém o serviço `browser` e suba novamente:

```bash
docker compose up -d
```

### Container não inicia

```bash
docker logs openclaw-gateway
docker logs openclaw-browser
```

### Não consegue acessar UI

```bash
# Verificar se container está healthy
docker ps | grep openclaw

# Teste direto
curl http://10.41.10.153:8080/healthz
```

### Permissões de arquivo

```bash
sudo chown -R 1000:1000 /DATA/AppData/openclaw/
```

## Stack Complementar

Seu OpenClaw faz parte do ecossistema CasaOS/Portainer:

| Serviço | IP | Porta | Uso |
|---------|-----|-------|-----|
| Portainer | 10.0.110.132 | 9001 | Gerenciamento |
| Caddy | 10.41.10.128 | 80/443 | Proxy reverso |
| Prometheus | 10.41.10.140 | 9090 | Monitoramento |
| **OpenClaw** | **10.41.10.153** | **8080** | **IA Pessoal** |

## Segurança

🔐 **Boas Práticas:**

- ✅ Use SSH tunnel para acesso remoto (não exponha porta direto)
- ✅ Gere token forte: `openssl rand -hex 32`
- ✅ Gere senha forte: `openssl rand -base64 16`
- ✅ API keys nunca aparecem em logs
- ✅ Browser sidecar isolado (sem IP externo)
- ✅ Dados isolados em volumes Docker
- ✅ Firewall ativo na VM

## Performance

**Requisitos Mínimos:**
- CPU: 2 cores
- RAM: 4GB (gateway) + 2GB (browser) = 6GB total
- Disco: 20GB

**Recomendado:**
- CPU: 4+ cores
- RAM: 8GB+
- Disco: 50GB+

## Licença

MIT License — veja [LICENSE](LICENSE)

## Referências

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [coollabsio/openclaw Docker Image](https://github.com/coollabsio/openclaw)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Portainer Documentation](https://docs.portainer.io/)

## Suporte

💬 Dúvidas ou sugestões?

- Abra uma [Issue](https://github.com/luanscps/openclaw-br/issues)
- Consulte a [Discussão](https://github.com/luanscps/openclaw-br/discussions)

---

**Criado por:** [luanscps](https://github.com/luanscps)  
**Última atualização:** Março 2026  
**Status:** ✅ Pronto para produção
