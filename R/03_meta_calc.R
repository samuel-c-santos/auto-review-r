# R/03_meta_calc.R
# Módulo de Bibliometria e Meta-Análise

library(tidyverse)
library(ggplot2)

# ==================== PARTE 1: BIBLIOMETRIA ====================

#' Análise bibliométrica completa
#' @param df Dataframe com resultados limpos
#' @return Lista com análises bibliométricas
analise_bibliometrica <- function(df) {
  
  message("📚 Executando análise bibliométrica...")
  
  resultados <- list(
    artigos_por_ano = bibli_por_ano(df),
    artigos_por_fonte = bibli_por_fonte(df),
    top_journals = top_journals(df),
    top_autores = top_autores(df),
    coautorias = analise_coautorias(df),
    palavras_chave = extrair_palavras(df)
  )
  
  return(resultados)
}

#' Artigos por ano
bibli_por_ano <- function(df) {
  df %>%
    filter(!is.na(year)) %>%
    count(year) %>%
    arrange(year)
}

#' Artigos por fonte
bibli_por_fonte <- function(df) {
  df %>% count(source_db)
}

#' Top journals
top_journals <- function(df, top_n = 15) {
  df %>%
    filter(!is.na(journal)) %>%
    count(journal, sort = TRUE) %>%
    head(top_n)
}

#' Top autores (primeiro autor)
top_autores <- function(df, top_n = 20) {
  df %>%
    filter(!is.na(authors)) %>%
    mutate(primeiro_autor = sapply(strsplit(authors, ";"), `[`, 1)) %>%
    count(primeiro_autor, sort = TRUE) %>%
    head(top_n)
}

#' Análise de coautorias
analise_coautorias <- function(df) {
  df %>%
    filter(!is.na(authors)) %>%
    mutate(n_autores = sapply(strsplit(authors, ";"), length)) %>%
    summarise(
      media_autores = mean(n_autores),
      min_autores = min(n_autores),
      max_autores = max(n_autores),
      total_autores_unicos = n_distinct(unlist(strsplit(authors, ";")))
    )
}

#' Extrair palavras-chave do título
extrair_palavras <- function(df, top_n = 30) {
  palavras <- df %>%
    pull(title) %>%
    tolower() %>%
    str_remove_all("[:punct:]") %>%
    str_split("\\s+") %>%
    unlist()
  
  stopwords <- c("the", "a", "an", "of", "and", "or", "in", "on", "at", "to", 
                 "for", "by", "with", "from", "is", "are", "was", "were",
                 "be", "been", "being", "have", "has", "had", "do", "does",
                 "did", "will", "would", "could", "should", "may", "might",
                 "can", "de", "la", "el", "en", "y", "da", "do", "das")
  
  palavras <- palavras[nchar(palavras) > 3 & !palavras %in% stopwords]
  
  tibble(palavra = palavras) %>%
    count(palavra, sort = TRUE) %>%
    head(top_n)
}

#' Visualizar top palavras
visualizar_palavras <- function(df, pasta_output = "data/03_visuals") {
  palavras <- extrair_palavras(df, 25)
  
  ggplot(palavras, aes(x = reorder(palavra, n), y = n, fill = n)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    labs(title = "Palavras mais frequentes nos titulos", x = "Palavra", y = "Frequencia") +
    theme_minimal() +
    theme(legend.position = "none") +
    scale_fill_gradient(low = "#3498db", high = "#2c3e50")
  
  ggsave(paste0(pasta_output, "/palavras_frequentes.png"), width = 10, height = 8)
}

# ==================== PARTE 2: ESTRUTURA META-ANÁLISE ====================

#' Template para dados de meta-análise
criar_template_meta <- function() {
  
  tibble(
    study_id = NA,
    autor_ano = NA,
    doi = NA,
    desenho = NA,
    n_total = NA,
    n_tratamento = NA,
    n_controle = NA,
    desfecho = NA,
    medida = NA,
    efeito = NA,
    ic_inferior = NA,
    ic_superior = NA,
    erro_padrão = NA,
    follow_up = NA,
    local = NA,
    pais = NA,
    observacoes = NA
  )
}

#' Criar formulário para extração
criar_formulario_extracao <- function(df) {
  
  df %>%
    select(title, authors, year, journal, doi, source_db) %>%
    mutate(
      estudo_id = row_number(),
      relevante = NA,
      criterios_inclusao = NA,
      risco_vies = NA,
      qualidade = NA,
      efeito_principal = NA,
      observacoes = NA
    ) %>%
    relocate(estudo_id, everything())
}

#' Exportar formulário para Excel
exportar_formulario <- function(df, nome_arquivo = "data/formulario_triagem.xlsx") {
  
  formulario <- criar_formulario_extracao(df)
  
  if (!dir.exists("data")) dir.create("data")
  
  writexl::write_xlsx(formulario, nome_arquivo)
  
  message(paste("Formulário salvo em:", nome_arquivo))
  message("Colunas para preenchimento:")
  message("  - relevante: TRUE/FALSE")
  message("  - criterios_inclusao: motivos")
  message("  - risco_vies: baixo/moderado/alto")
  message("  - qualidade: escore")
}

# ==================== PARTE 3: IMPORTAÇÃO ====================

#' Importar dados de meta-análise
importar_dados_meta <- function(caminho) {
  
  if (grepl("\\.xlsx$", caminho)) {
    df <- readxl::read_excel(caminho)
  } else if (grepl("\\.csv$", caminho)) {
    df <- read_csv(caminho)
  } else {
    stop("Formato não suportado. Use .xlsx ou .csv")
  }
  
  return(df)
}

#' Resumo do progresso da revisão
resumo_revisao <- function(df_completo, df_triagem) {
  
  n_total <- nrow(df_completo)
  n_incluidos <- sum(df_triagem$relevante == TRUE, na.rm = TRUE)
  n_excluidos <- sum(df_triagem$relevante == FALSE, na.rm = TRUE)
  n_pendentes <- sum(is.na(df_triagem$relevante))
  
  cat("\n=== RESUMO DA REVISÃO ===\n")
  cat("Artigos identificados:", n_total, "\n")
  cat("  - Incluídos:", n_incluidos, "\n")
  cat("  - Excluídos:", n_excluidos, "\n")
  cat("  - Pendentes:", n_pendentes, "\n")
  cat("Taxa de inclusão:", round(n_incluidos/n_total*100, 1), "%\n")
}
