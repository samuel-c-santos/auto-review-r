# Auto-Review-R

Sistema de revisão sistemática automatizada em R. Busca artigos científicos em múltiplas bases de dados, limpa, analisa e gera visualizações.

## Bases de Dados Suportadas

| Fonte | Cobertura | API Key |
|-------|-----------|---------|
| **PubMed** | Biomedical/Saúde | Não |
| **CrossRef** | Universal | Não |
| **OpenAlex** | Universal (aberta) | Não |
| **Semantic Scholar** | Acadêmico | Recomendado |

## Instalação

```r
# Instalar dependências
source("requirements.R")
```

## Como Usar

### 1. Configure sua pesquisa

Edite o arquivo `_main.R` no início:

```r
# ==================== CONFIGURAÇÃO ====================
TERMO_BUSCA <- "remote sensing deforestation amazon"  # Termo de busca
MAX_RESULTADOS <- 100                                  # Artigos por fonte
ANO_MIN <- 2020                                        # Ano mínimo (NULL = sem filtro)
ANO_MAX <- NULL                                        # Ano máximo (NULL = sem filtro)
FONTES <- c("pubmed", "crossref", "openalex")          # Fontes ativas
```

### 2. Execute o pipeline

```bash
Rscript _main.R
```

### 3. Saídas geradas

```
data/
├── 01_raw/                    # Dados brutos da busca
├── 02_processed/             # Dados limpos (CSV)
├── 03_visuals/               # Gráficos gerados
│   ├── artigos_por_ano.png
│   ├── artigos_por_fonte.png
│   ├── top_journals.png
│   ├── timeline.png
│   └── palavras_frequentes.png
└── formulario_triagem.xlsx   # Para triagem manual
```

## Exemplo de Uso Programático

```r
source("R/01_buscadores.R")
source("R/02_limpeza.R")

# Busca
resultados <- buscar_todas("climate change Brazil", max_n = 50)

# Limpeza
limpos <- limpar_resultados(resultados)

# Filtrar
limpos <- filtrar_por_ano(limpos, ano_min = 2020)
```

## Estrutura do Projeto

```
Auto-Review-R/
├── _main.R                 # Pipeline completo (configure aqui!)
├── requirements.R          # Dependências
├── README.md               # Este arquivo
├── AGENDA.md               # Próximos passos
└── R/
    ├── 01_buscadores.R     # Busca (PubMed, CrossRef, OpenAlex, Semantic)
    ├── 02_limpeza.R        # Limpeza e deduplicação
    ├── 03_meta_calc.R      # Bibliometria e estrutura meta-análise
    └── 04_visualizacao.R   # Gráficos
```

## API Keys

### Semantic Scholar (opcional)
1. Acesse https://www.semanticscholar.org/api
2. Solicite acesso (gratuito para uso acadêmico)
3. Adicione a key no código quando receber

## Licença

MIT
