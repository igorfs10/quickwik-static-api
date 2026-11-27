---
trigger: always_on
---

# Regra Obrigatória de Validação de JSON (`wiki-json-validator`)

Sempre que qualquer arquivo em `games/*.json`, `games/images/**` ou `games_manifest.json` for criado ou modificado neste repositório (`quickwik-static-api`):

1. **Passagem Obrigatória pelo Subagente Validador**:
   - É **ESTRITAMENTE PROIBIDO** executar `git commit` antes de invocar o subagente **`wiki-json-validator`** (`invoke_subagent` com `TypeName: "wiki-json-validator"`) sobre o(s) arquivo(s) criado(s)/alterado(s) e receber **`VEREDICTO: APROVADO`**.
2. **Gate Automático Determinístico**:
   - O subagente `wiki-json-validator` deve obrigatoriamente executar `.agents/scripts/validate-wiki-json.ps1` (com `-GameId <id>` para o jogo alterado ou completo) e confirmar ausência total de erros de schema Rust (`id`, `title`, `icon`, `updated_at`, `sources`, `process_keywords`, `categories`, `entries`), campos legados proibidos (`game_id`, `version`), estabilidade de `entries[].id` contra o `HEAD`, cabeçalhos `.webp` válidos, termos proibidos de glossário e sincronização dos 3 `updated_at`.
3. **Ciclo de Correção**:
   - Se o veredito for **`VEREDICTO: REPROVADO`**, corrija **todos** os erros reportados e invoque novamente o subagente **`wiki-json-validator`** até obter **`VEREDICTO: APROVADO`** antes de commitar.
4. **Exceção Zero**:
   - Nunca pule esta etapa alegando pressa, tamanho pequeno da mudança ou script local próprio; todo commit de dados de jogo só ocorre após aprovação explícita do `wiki-json-validator`.
