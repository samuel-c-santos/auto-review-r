# ==================== CONFIGURAÇÃO ====================
# Altere aqui os parâmetros da sua pesquisa
TERMO_BUSCA <- "reserva legal amazonia"        # Termo de busca
MAX_RESULTADOS <- 50                          # Número máximo de artigos por fonte
ANO_MIN <- NULL                               # Ano mínimo (NULL = sem filtro)
ANO_MAX <- NULL                               # Ano máximo (NULL = sem filtro)
FONTES <- c("pubmed", "crossref", "openalex", "semantic")  # Fontes a buscar

# ==================== PIPELINE ====================
source("requirements.R")
source("R/01_buscadores.R")
source("R/02_limpeza.R")
source("R/04_visualizacao.R")
source("R/03_meta_calc.R")

message(paste("🔍 Buscando:", TERMO_BUSCA))

# 1. Executar busca
resultados <- buscar_todas(TERMO_BUSCA, max_n = MAX_RESULTADOS, fontes = FONTES)

if (is.null(resultados) || nrow(resultados) == 0) {
  stop("Nenhum resultado encontrado!")
}

# 2. Limpar
resultados_limpos <- limpar_resultados(resultados)

# 3. Filtrar por ano (se definido)
if (!is.null(ANO_MIN) | !is.null(ANO_MAX)) {
  resultados_limpos <- filtrar_por_ano(resultados_limpos, ANO_MIN, ANO_MAX)
}

# 4. Visualização
resumo_stats(resultados_limpos)
gerar_visuais(resultados_limpos)

# 5. Bibliometria
analise_bibliometrica(resultados_limpos)
visualizar_palavras(resultados_limpos)

# 6. Formulário para triagem
exportar_formulario(resultados_limpos)

# 7. Salvar CSV final
if (!dir.exists("data/02_processed")) dir.create("data/02_processed", recursive = TRUE)
nome_csv <- paste0("data/02_processed/", gsub(" ", "_", TERMO_BUSCA), "_", Sys.Date(), ".csv")
exportar_duckdb(resultados_limpos, nome_csv)

cat("\n✅ Concluido! Arquivos em data/\n")