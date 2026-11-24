---
name: quickwik-glossary
description: Glossário de Linguagem Ubíqua e guia de UX Writing do QuickWik. Consulte SEMPRE que criar ou editar textos visíveis ao usuário nos arquivos JSON da Wiki (títulos, subtítulos, categorias, cards de detalhes) ou na interface do QuickWik.
---

# QuickWik Glossary — Linguagem Ubíqua & UX Writing

Esta skill define a **Linguagem Ubíqua** oficial do ecossistema **QuickWik** (`quickwik` desktop + `quickwik-static-api`) e as diretrizes de **UX Writing** e redação de conteúdo para jogadores.

---

## 1. Regra de Ouro de UX Writing e Redação de Guias

O usuário final do QuickWik é um **gamer consultando um overlay rápido no meio da partida (`Alt+F12`)**, não um desenvolvedor.

- **Idioma**: Sempre Português Brasileiro (**PT-BR**), natural, direto, escaneável e sem jargões técnicos internos.
- **Nomes Bilíngues de Itens/Troféus**: Quando um jogo for muito conhecido pelos termos em inglês e português na comunidade, mantenha ambos no título da entrada ou nas `tags` para facilitar a busca (ex.: `"Golden Seed (Semente Dourada)"`, `"S&S M232 (Pistola — Grace)"`).
- **Termos Técnicos de Sistema Proibidos no Texto Visível ao Jogador**:
  - `API`, `Manifesto`, `JSON`, `Payload`, `Schema`
  - `Cache` (use *"Salvo no PC"* ou *"Instalado"*)
  - `Processo`, `PID`, `Binário` (use *"Jogo Aberto"* ou *"Executável detectado"*)
  - `Thread`, `Callback`, `URI`, `ShellExecute`

---

## 2. Tabela Oficial de Linguagem Ubíqua (JSON / Código vs. Jogador)

| Conceito | Identificador no JSON / Código | Termo Amigável para o Jogador (PT-BR) | Termos Proibidos |
|---|---|---|---|
| Repositório `games_manifest.json` | `manifest`, `games` | **Catálogo de Jogos** / **Catálogo Online** | "API", "Manifesto", "JSON", "Endpoint" |
| Arquivo `games/<id>.json` | `GameJsonData`, `entries` | **Guia do Jogo** / **Conteúdo da Wiki** | "JSON do jogo", "Payload" |
| Aba de filtro em `categories` | `categories[].id`, `categories[].label` | **Categoria** (ex.: `Todos`, `🔫 Armas`, `🏆 Guia de Platina`, `🗺️ Mapas`) | IDs crus sem ícone/tradução |
| Tópico da lista lateral (`entries[]`) | `WikiEntryJson` (`title`, `subtitle`) | **Item da Wiki** / **Tópico** | "Registro", "Row", "Node" |
| Bloco dentro de `additional_data[]` | `AdditionalDataJson` (`title`, `type`, `content`, `color`) | **Card** / **Bloco de Detalhe** (fixável na tela com `📌 Fixar Card`) | "Additional Data", "Sub-objeto" |
| Bloco `"type": "image"` | `image`, `games/images/<id>/<file>.webp` | **Imagem / Mapa** (abre com `🔍 Visualizar` em janela com Pan & Zoom) | "Asset", "Texture", "Raw file" |
| Bloco `"type": "youtube"` | `youtube`, `https://www.youtube.com/watch?v=...` | **Vídeo-Guia (YouTube)** (`▶ Assistir em PiP` ou `🌐 Abrir no Navegador`) | "External URI", "Embed URL" |
| Executáveis em `process_keywords` | `process_keywords: ["eldenring", ...]` | **Detecção Automática de Jogo** (`DETECTADO`) | "Target PID", "Process Hook" |

---

## 3. Padrão de Redação para `entries[]` e `additional_data[]` nos JSONs

1. **`title` e `subtitle` da Entrada (`entries[]`)**:
   - **`title`**: Nome claro do item, arma, chefe, missão, mapa ou troféu.
   - **`subtitle`**: Resumo telegráfico em **1 única linha** com as informações mais importantes para identificação rápida na lista lateral (ex.: `"🔫 Grace • Pistola principal de precisão • Dano Base: 120"` ou `"🏆 Troféu de Ouro • ⚠️ Perdível • Capítulo 4"`).
2. **Títulos e Cores Semânticas dos Cards (`additional_data[]`)**:
   - **`"cyan"` / `"blue"`** (`Descrição`, `Resumo`, `Efeito`): O que o item, habilidade ou troféu faz.
   - **`"yellow"` / `"orange"`** (`Localização`, `Onde Encontrar`, `Código / Senha`, `Requisitos`): Passo a passo objetivo de onde pegar, preço em NPCs ou combinação exata de cofre (fácil de copiar com o botão **`📋 Copiar`**).
   - **`"green"`** (`Estratégia`, `Dica de Combate`, `Como Conquistar`, `Upgrade Recomendado`): Táticas práticas usando bullet points (`• `).
   - **`"gray"`** (`Mecânica`, `Atributos`, `Dados Técnicos`): Valores numéricos, escalonamento, durações e cooldowns.
   - **`"red"`** (`⚠️ Atenção (Perdível)`, `Fraqueza / Perigo Letal`): Avisos críticos que podem bloquear 100% / Platina ou matar o jogador instantaneamente.
   - **`"purple"` / `"pink"`** (`Segredo`, `Sinergia Arcana`, `Lore`): Interações ocultas, segredos ou contexto extra.
3. **Formatação Escaneável**:
   - Prefira listas com `• ` separadas por `\n` em vez de parágrafos longos.
   - Coloque senhas, códigos de cofre ou sequências de botões em um card próprio e enxuto para que o botão **`📋 Copiar`** do QuickWik copie apenas o texto útil ao jogador.
