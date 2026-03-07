# Agenda de Desenvolvimento - Auto-Review-R

## Fase 1: Busca de Artigos ✅ CONCLUÍDO

- [x] PubMed - funcionando
- [x] CrossRef - funcionando
- [x] OpenAlex - funcionando
- [x] Semantic Scholar - pendente API key
- [x] Função buscar_todas() - combinando resultados

## Fase 2: Limpeza e Processamento ✅ CONCLUÍDO

- [x] Remover duplicatas (por DOI/título)
- [x] Normalizar títulos
- [x] Padronizar anos
- [x] Detectar idioma
- [x] Classificar por relevância
- [x] Exportar CSV otimizado para DuckDB

## Fase 3: Visualização ✅ CONCLUÍDO

- [x] Artigos por ano
- [x] Artigos por fonte
- [x] Top journals
- [x] Timeline
- [x] Palavras frequentes

## Fase 4: Bibliometria ✅ CONCLUÍDO

- [x] Análise por ano
- [x] Análise por fonte
- [x] Top journals
- [x] Top autores
- [x] Coautorias
- [x] Extração de palavras-chave

## Fase 5: Triagem [EM DESENVOLVIMENTO]

- [x] Formulário Excel para triagem manual
- [ ] Interface para revisar títulos/resumos
- [ ] Critérios de inclusão/exclusão
- [ ] Fluxo PRISMA
- [ ] Importar dados triados

## Fase 6: Meta-Análise

- [ ] Estrutura de dados para effect sizes
- [ ] Cálculos estatísticos (metafor)
- [ ] Forest plots
- [ ] Funnel plots
- [ ] Análise de heterogeneidade

## Fase 7: Relatórios

- [ ] Relatório automático (R Markdown)
- [ ] Dashboard interativo
- [ ] Exportar BibTeX/RIS

## Como Configurar

Edite `_main.R` no topo:

```r
TERMO_BUSCA <- "sua busca aqui"
MAX_RESULTADOS <- 50
ANO_MIN <- 2020
FONTES <- c("pubmed", "crossref", "openalex")
```

## Próximos Passos Imediatos

1. ✅ Pipeline completo funcionando
2. ⏳ Aguardar API key do Semantic Scholar
3. ⏳ Testar com busca real maior
4. ⏳ Desenvolver interface de triagem

---

*Última atualização: 2026-03-07*
