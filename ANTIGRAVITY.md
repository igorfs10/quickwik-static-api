# QuickWik Static API (`quickwik-static-api`) — Diretrizes do Repositório

Este repositório hospeda o **Catálogo Online (`games_manifest.json`)**, os **Guias de Jogos (`games/<game_id>.json`)** e as **Imagens/Mapas (`games/images/<game_id>/*.webp`)** consumidos pelo aplicativo desktop **QuickWik** (`https://igorfs10.github.io/quickwik-static-api/`).

---

## 1. Estrutura de Arquivos do Repositório

```text
.
├── ANTIGRAVITY.md                          # Regras gerais deste repositório para o agente
├── games_manifest.json                     # Catálogo mestre com lista de jogos, URLs relativas e timestamps
├── games/
│   ├── <game_id>.json                      # Guia completo da Wiki do jogo (ex.: elden_ring.json)
│   └── images/
│       └── <game_id>/
│           └── <arquivo>.webp              # Imagens e mapas referenciados em additional_data ("type": "image")
└── .agents/
    ├── agents/
    │   └── wiki-data-curator.md            # Subagente especialista em pesquisa e criação/atualização dos JSONs
    └── skills/
        └── quickwik-glossary/
            └── SKILL.md                    # Glossário de Linguagem Ubíqua e padrão de redação PT-BR dos guias
```

---

## 2. Agente e Skill Especializados

Sempre que o usuário pedir para **criar um novo guia de jogo**, **adicionar ou expandir categorias/itens**, **atualizar informações**, **adicionar mapas/imagens ou vídeos do YouTube** ou **sincronizar o `games_manifest.json`**:

1. **Consulte ou delegue ao agente `wiki-data-curator`** (`.agents/agents/wiki-data-curator.md`):
   - Pesquisa fatos verificados na web (`search_web`) cruzando múltiplas fontes confiáveis (wikis, guias de troféus, SteamDB/PCGamingWiki para `process_keywords`).
   - Aplica a **Regra Inegociável Anti-Plágio** (extração apenas de fatos objetivos com redação 100% própria em formato de ficha técnica para overlay e registro obrigatório em `"sources"`).
   - Segue rigorosamente o schema JSON esperado pelo cliente Rust do QuickWik (`GamesManifest` e `GameJsonData`).
2. **Aplique a skill `quickwik-glossary`** (`.agents/skills/quickwik-glossary/SKILL.md`):
   - Mantém toda a redação dos guias em **Português Brasileiro (PT-BR)** natural, direto e escaneável (com bullet points `• `, subtítulos telegráficos e cores semânticas padronizadas nos cards de `additional_data`).

---

## 3. Regras Críticas de Integridade dos JSONs

1. **Estabilidade de IDs (`entries[].id`)**:
   - **NUNCA** altere, remova ou reaproveite o `id` numérico de uma entrada existente ao atualizar um jogo. O aplicativo QuickWik salva os **Favoritos**, **Itens Ocultos**, **Cards Fixados** e **Imagens Fixadas** do jogador vinculados a esse `id`. Novas entradas devem sempre receber um novo `id` sequencial.
2. **Sincronização de Timestamps (`updated_at`)**:
   - Sempre que criar ou editar `games/<game_id>.json`, atualize o campo `"updated_at"` (formato ISO-8601 UTC terminado em `Z`, ex.: `"2026-11-24T19:00:00Z"`) em **3 lugares**:
     1. Na raiz de `games/<game_id>.json`;
     2. Na entrada correspondente do jogo dentro de `games_manifest.json`;
     3. No campo `"updated_at"` global na raiz de `games_manifest.json`.
3. **Caminhos Seguros de Imagens (`"type": "image"`)**:
   - O campo `"content"` de uma imagem deve conter **apenas o nome do arquivo** (ex.: `"mapa_1f.webp"`), sem barras (`/` ou `\`) e sem `..`. O arquivo deve estar salvo em `games/images/<game_id>/<nome_arquivo>`.
4. **Execução 1 a 1, Commit Local e Push Manual**:
   - Ao criar ou refinar múltiplos jogos, processe **1 jogo por vez** (pesquisa, download/verificação de imagens `.webp` oficiais do jogo quando aplicável, escrita de `games/<game_id>.json`, sincronização de `games_manifest.json` e validação completa).
   - Após validar cada jogo, faça **1 `git commit` local atômico** contendo apenas os arquivos daquele jogo (`games/<game_id>.json`, `games/images/<game_id>/` e `games_manifest.json`) com mensagem descritiva (ex.: `feat(<game_id>): ...` ou `refine(<game_id>): ...`).
   - **NUNCA execute `git push` automaticamente**. Deixe os commits locais prontos na branch `main` para revisão e `git push` manual pelo usuário (que aciona o workflow `.github/workflows/sync-web.yml` para publicar na branch `web`).
