# R/02_limpeza.R
# Módulo de limpeza e processamento de dados

library(tidyverse)
library(janitor)

#' Limpar e deduplicar resultados de busca
#' @param df Dataframe com resultados de busca
#' @return Dataframe limpo e deduplicado
limpar_resultados <- function(df) {
  
  message("🧹 Iniciando limpeza...")
  
  df_limpo <- df %>%
    # 1. Remover duplicatas por DOI (preferência) ou título
    deduplicar() %>%
    # 2. Normalizar títulos
    normalizar_titulos() %>%
    # 3. Normalizar anos
    normalizar_anos() %>%
    # 4. Detectar idioma
    detectar_idioma() %>%
    # 5. Classificar por relevância
    classificar_relevancia()
  
  message(paste("✅ Limpeza concluída:", nrow(df_limpo), "artigos únicos"))
  
  return(df_limpo)
}

#' Remover duplicatas por DOI ou título
deduplicar <- function(df) {
  
  n_original <- nrow(df)
  
  # Normalizar título para comparação (minúsculas, remover espaços extras)
  df <- df %>%
    mutate(
      titulo_normalizado = tolower(trimws(title)),
      doi_normalizado = tolower(trimws(doi))
    )
  
  # Se tiver DOI, usar para deduplicação
  if ("doi" %in% names(df) && any(!is.na(df$doi_normalizado))) {
    df_sem_dup <- df %>%
      group_by(doi_normalizado) %>%
      slice(1) %>%
      ungroup()
    
    n_por_doi <- nrow(df_sem_dup)
    
    # Se ainda houver duplicatas pelo título
    df_sem_dup <- df_sem_dup %>%
      group_by(titulo_normalizado) %>%
      slice(1) %>%
      ungroup()
  } else {
    # Sem DOI, usar apenas título
    df_sem_dup <- df %>%
      group_by(titulo_normalizado) %>%
      slice(1) %>%
      ungroup()
  }
  
  # Remover colunas temporárias
  df_sem_dup <- df_sem_dup %>% select(-titulo_normalizado, -doi_normalizado)
  
  n_final <- nrow(df_sem_dup)
  n_duplicatas <- n_original - n_final
  
  if (n_duplicatas > 0) {
    message(paste("  - Removidas", n_duplicatas, "duplicatas"))
  }
  
  return(df_sem_dup)
}

#' Normalizar títulos (trim, espaços extras)
normalizar_titulos <- function(df) {
  df %>%
    mutate(
      title = trimws(title),
      title = str_squish(title)
    )
}

#' Normalizar anos (extrair apenas números de 4 dígitos)
normalizar_anos <- function(df) {
  df %>%
    mutate(
      year = as.character(year),
      year = str_extract(year, "\\d{4}"),
      year = as.integer(year)
    )
}

#' Detectar idioma básico do título
detectar_idioma <- function(df) {
  # Simples: se tiver caracteres não-ASCII comuns em português/espanhol
  df %>%
    mutate(
      idioma = case_when(
        grepl("[áéíóúàèìòùãẽĩõũâêîôûçñ]", title, ignore.case = TRUE) ~ "pt_es",
        TRUE ~ "en"
      )
    )
}

#' Classificar por relevância (ano mais recente primeiro)
classificar_relevancia <- function(df) {
  df %>%
    arrange(desc(year), title)
}

#' Filtrar por ano
filtrar_por_ano <- function(df, ano_min = NULL, ano_max = NULL) {
  if (!is.null(ano_min)) {
    df <- df %>% filter(year >= ano_min)
  }
  if (!is.null(ano_max)) {
    df <- df %>% filter(year <= ano_max)
  }
  return(df)
}

#' Filtrar por fonte
filtrar_por_fonte <- function(df, fontes = NULL) {
  if (!is.null(fontes)) {
    df <- df %>% filter(source_db %in% fontes)
  }
  return(df)
}

#' Exportar para CSV otimizado para DuckDB
exportar_duckdb <- function(df, nome_arquivo) {
  # Garantir tipos corretos para DuckDB
  df <- df %>%
    mutate(
      title = as.character(title),
      authors = as.character(authors),
      journal = as.character(journal),
      year = as.integer(year),
      doi = as.character(doi),
      source_db = as.character(source_db),
      search_term = as.character(search_term),
      fetched_at = as.character(fetched_at)
    )
  
  write_csv(df, nome_arquivo)
  message(paste("Exportado para:", nome_arquivo))
}
