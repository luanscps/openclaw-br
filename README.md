# 🦞 OpenClaw Brasil — Docker + Caddy SSL + macvlan-dhcp

> Assistente de IA Pessoal rodando em sua infraestrutura própria com HTTPS nativo

[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/luanscps/openclaw-br?style=flat-square)](https://github.com/luanscps/openclaw-br/issues)

## Visão Geral

Instalação otimizada do [OpenClaw](https://docs.openclaw.ai) para ambientes com Docker, Portainer e rede **macvlan-dhcp** já configurada. Inclui **Caddy** como proxy reverso com SSL automático (certificado autoassinado via `tls internal`), resolvendo o requisito de HTTPS da Control UI.

> **Imagem utilizada:** [`coollabsio/openclaw:latest`](https://github.com/coollabsio/openclaw) — imagem pré-compilada com nginx + gateway embutidos.

🎯 **Objetivo:** Deploy pronto em ~20 minutos com HTTPS funcionando de imediato.

---

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
- ✅ Rede **macvlan-dhcp** já criada
- ✅ API Key do Anthropic (Claude) ou OpenAI (GPT)
- ✅ SSH acesso ao servidor

---

## Arquitetura

| Componente | Especificação |
|---|---|
| **Proxy SSL** | caddy (caddy:alpine) |
| **IP público** | 10.41.10.153 (via macvlan) |
| **Porta de acesso** | 443 HTTPS / 80 → redirect |
| **Container principal** | openclaw-gateway |
| **Imagem** | coollabsio/openclaw:latest |
| **Porta interna UI** | 8080 (sem exposição externa) |
| **Porta gateway** | 18789 (loopback only) |
| **Container browser** | openclaw-browser |
| **Imagem browser** | kasmweb/chrome:1.16.0 |
| **Diretório de dados** | /DATA/AppData/openclaw/ |
| **Rede externa** | macvlan-dhcp (só o Caddy) |
| **Rede interna** | openclaw-internal (bridge) |

### Diagrama de Rede

```
Sua rede local (macvlan-dhcp)
         │
         ▼  https://10.41.10.153  (porta 443)
┌─────────────────────────────────────────────┐
│  caddy (caddy:alpine)                       │
│  TLS interno (certificado autoassinado)     │
│  reverse_proxy → openclaw-gateway:8080      │
└────────────┬────────────────────────────────┘
             │ openclaw-internal (bridge)
             ▼  http://openclaw-gateway:8080
┌──────────────────────────────────────────────────────┐
│  openclaw-gateway (coollabsio/openclaw)              │
│  nginx :8080  ──▶  gateway ws://127.0.0.1:18789      │
│  Login: admin / AUTH_PASSWORD                        │
└────────────────────┬─────────────────────────────────┘
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

> **Por que Caddy?** A Control UI do OpenClaw exige contexto seguro (HTTPS) para gerar a *device identity* via Web Crypto API. Sem HTTPS, o browser bloqueia e a UI não conecta.

---

## Estrutura de Arquivos

```
openclaw-br/
├── docker-compose.yml          # Stack: caddy + gateway + browser
├── Caddyfile                   # Config do proxy SSL (tls internal)
├── .env.example                # Template de variáveis de ambiente
├── setup-verificacao.sh        # Script automático de validação
├── README.md                   # Este arquivo
└── LICENSE                     # MIT License
```

---

## Quickstart (~20 minutos)

### 1️⃣ Clonar o Repositório

```bash
cd /DATA/AppData
git clone https://github.com/luanscps/openclaw-br.git openclaw
cd openclaw
```

### 2️⃣ Preparar Estrutura

```bash
chmod +x setup-verificacao.sh
./setup-verificacao.sh
```

O script cria todos os diretórios necessários e valida a rede macvlan automaticamente.

### 3️⃣ Configurar Credenciais

```bash
cp .env.example .env
nano .env
```

Edite no mínimo:

| Variável | Como gerar | Exemplo |
|---|---|---|
| `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) | `sk-ant-...` |
| `OPENCLAW_GATEWAY_TOKEN` | `openssl rand -hex 32` | `a1b2c3...` |
| `AUTH_PASSWORD` | `openssl rand -base64 16` | `XyZ123...` |
| `SERVER_IP` | IP macvlan do servidor | `10.41.10.153` |

### 4️⃣ Copiar Caddyfile

```bash
cp Caddyfile /DATA/AppData/openclaw/Caddyfile
```

Se quiser usar um IP diferente do padrão, edite:
```bash
nano /DATA/AppData/openclaw/Caddyfile
# Troque 10.41.10.153 pelo seu SERVER_IP
```

### 5️⃣ Deploy

```bash
docker compose up -d
docker compose logs -f
```

### 6️⃣ Aceitar o Certificado Autoassinado

No browser, acesse `https://10.41.10.153` (ou seu `SERVER_IP`).

O browser vai exibir aviso de segurança — é esperado:
- **Chrome:** Clique em *Avançado* → *Prosseguir para 10.41.10.153*
- **Firefox:** Clique em *Avançado* → *Aceitar o risco e continuar*

> ⚠️ **Aceitar o certificado é obrigatório uma vez.** Sem isso, a Web Crypto API não consegue gerar a device identity e a UI não conecta.

### 7️⃣ Login na UI

Login: `admin` / senha definida em `AUTH_PASSWORD` do `.env`

### 8️⃣ Configurar Token na UI

Na página **Visão Geral**, preencha:

- **URL WebSocket:** `wss://10.41.10.153` (use `wss://`, não `ws://`)
- **Token do Gateway:** cole o valor de `OPENCLAW_GATEWAY_TOKEN` do seu `.env`

Clique em **Atualizar** e depois **Conectar**.

### 9️⃣ Aprovar Device Pairing (primeiro acesso)

No primeiro acesso, a UI pede aprovação do dispositivo. Execute no servidor:

```bash
# Ver dispositivos aguardando aprovação
docker exec openclaw-gateway openclaw devices list

# Aprovar (substitua pelo requestId exibido)
docker exec openclaw-gateway openclaw devices approve <requestId>
```

Após aprovado, recarregue a página — o status ficará **OK** ✅.

> A aprovação é salva permanentemente. Novos dispositivos/browsers precisam ser aprovados individualmente.

---

## Variáveis de Ambiente (.env)

| Variável | Descrição | Obrigatório |
|---|---|---|
| `ANTHROPIC_API_KEY` | Chave do Claude (Anthropic) | Sim (ou OpenAI) |
| `OPENAI_API_KEY` | Chave do GPT-4o (OpenAI) | Alternativa |
| `OPENCLAW_GATEWAY_TOKEN` | Token seguro do gateway | Sim |
| `AUTH_PASSWORD` | Senha da interface web (nginx) | Sim |
| `SERVER_IP` | IP macvlan do servidor | Sim |
| `OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS` | Origin HTTPS permitida para a UI | Sim |
| `OPENCLAW_GATEWAY_TRUSTED_PROXIES` | Proxies confiáveis (nginx interno) | Sim |
| `TELEGRAM_BOT_TOKEN` | Token do bot Telegram | Não |
| `DISCORD_BOT_TOKEN` | Token do bot Discord | Não |

---

## Volumes Mapeados

```
/DATA/AppData/openclaw/config      → /data/.openclaw   (openclaw-gateway)
/DATA/AppData/openclaw/workspace   → /data/workspace   (openclaw-gateway)
/DATA/AppData/openclaw/caddy-data  → /data             (caddy)
/DATA/AppData/openclaw/caddy-config→ /config           (caddy)
/DATA/AppData/openclaw/Caddyfile   → /etc/caddy/Caddyfile (caddy)
```

> ⚠️ **Não monte volume em `/home/kasm-user`** do container browser. O kasmweb usa UID interno que conflita com o host, causando `Permission denied` na inicialização do Chrome.

---

## Operações Comuns

### Ver Status

```bash
docker compose ps
```

### Ver Logs

```bash
# Tempo real — todos os serviços
docker compose logs -f

# Só o gateway
docker compose logs -f openclaw-gateway

# Só o caddy
docker compose logs -f caddy
```

### Parar / Reiniciar

```bash
docker compose down
docker compose up -d

# Recriar com nova imagem
docker compose pull
docker compose up -d --force-recreate
```

### Backup

```bash
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz \
  /DATA/AppData/openclaw/config \
  /DATA/AppData/openclaw/workspace
```

---

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

---

## Troubleshooting

### `origin not allowed`

O `openclaw.json` tem o origin errado. Corrija:

```bash
jq '.gateway.controlUi.allowedOrigins = ["https://SEU_IP"]' \
  /DATA/AppData/openclaw/config/openclaw.json > /tmp/new.json \
  && mv /tmp/new.json /DATA/AppData/openclaw/config/openclaw.json
docker restart openclaw-gateway
```

> ⚠️ O entrypoint do container recria o `openclaw.json` a cada restart com base nas variáveis de ambiente. Use `OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS` no `.env` para persistir.

### `control ui requires device identity (use HTTPS or localhost)`

A Control UI só funciona em contexto HTTPS. Verifique:
- O Caddy está rodando: `docker compose ps caddy`
- Você aceitou o certificado no browser
- Está acessando `https://` (não `http://`)

### `gateway token missing`

A UI precisa do token para conectar. Na página Visão Geral:
1. **URL WebSocket:** `wss://SEU_IP`
2. **Token:** valor de `OPENCLAW_GATEWAY_TOKEN` do `.env`
3. Clique **Atualizar** → **Conectar**

### `too many failed authentication attempts (retry later)`

Rate limit ativado após muitas tentativas falhas. Solução:

```bash
docker restart openclaw-gateway
```

Aguarde 30 segundos e tente novamente.

### `pairing required`

Primeiro acesso de um novo dispositivo exige aprovação:

```bash
docker exec openclaw-gateway openclaw devices list
docker exec openclaw-gateway openclaw devices approve <requestId>
```

### `Permission denied` no browser (kasmweb)

Não monte volume em `/home/kasm-user`. O kasmweb usa UID interno (1000) que pode conflitar. Remova o volume do serviço `browser` no `docker-compose.yml`.

### Container não inicia

```bash
docker logs openclaw-gateway
docker logs openclaw-caddy
docker logs openclaw-browser
```

### Não consegue acessar a UI

```bash
# Verificar se todos estão rodando
docker compose ps

# Testar Caddy diretamente
curl -k https://10.41.10.153/healthz
```

---

## Segurança

🔐 **Boas Práticas:**

- ✅ HTTPS nativo via Caddy com TLS interno
- ✅ Gateway escuta apenas em loopback (`127.0.0.1:18789`)
- ✅ Apenas o Caddy expõe IP na rede macvlan
- ✅ Browser sidecar isolado (sem IP externo)
- ✅ Device pairing obrigatório no primeiro acesso
- ✅ Gere token forte: `openssl rand -hex 32`
- ✅ Gere senha forte: `openssl rand -base64 16`
- ✅ API keys nunca aparecem em logs

---

## Performance

**Requisitos Mínimos:**
- CPU: 2 cores
- RAM: 4GB (gateway) + 2GB (browser) = 6GB total
- Disco: 20GB

**Recomendado:**
- CPU: 4+ cores
- RAM: 8GB+
- Disco: 50GB+

---

## Stack Complementar

| Serviço | IP | Porta | Uso |
|---|---|---|---|
| Portainer | 10.0.110.132 | 9001 | Gerenciamento |
| Prometheus | 10.41.10.140 | 9090 | Monitoramento |
| **OpenClaw** | **10.41.10.153** | **443 (HTTPS)** | **IA Pessoal** |

---

## Licença

MIT License — veja [LICENSE](LICENSE)

---

## Referências

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Control UI Auth](https://docs.openclaw.ai/web/dashboard)
- [Device Pairing](https://docs.openclaw.ai/web/control-ui#device-pairing-first-connection)
- [coollabsio/openclaw Docker Image](https://github.com/coollabsio/openclaw)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

**Criado por:** [luanscps](https://github.com/luanscps)  
**Última atualização:** Março 2026  
**Status:** ✅ Pronto para produção
