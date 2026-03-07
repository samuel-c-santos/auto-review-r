# R/04_visualizacao.R
# Módulo de visualização para revisão sistemática

library(tidyverse)
library(ggplot2)

#' Gerar visualizações para resultados de busca
#' @param df Dataframe com resultados limpos
#' @param pasta_output Pasta para salvar gráficos
gerar_visuais <- function(df, pasta_output = "data/03_visuals") {
  
  if (!dir.exists(pasta_output)) dir.create(pasta_output, recursive = TRUE)
  
  message("📊 Gerando visualizações...")
  
  # 1. Artigos por ano
  grafico_anos(df, pasta_output)
  
  # 2. Artigos por fonte
  grafico_fontes(df, pasta_output)
  
  # 3. Top journals
  grafico_journals(df, pasta_output)
  
  # 4. Timeline
  grafico_timeline(df, pasta_output)
  
  message(paste("✅ Visualizações salvas em:", pasta_output))
}

#' Artigos por ano
grafico_anos <- function(df, pasta_output) {
  
  dados <- df %>%
    filter(!is.na(year)) %>%
    count(year)
  
  ggplot(dados, aes(x = year, y = n)) +
    geom_bar(fill = "#3498db", stat = "identity") +
    geom_text(aes(label = n), vjust = -0.5, size = 3) +
    labs(
      title = "Artigos por Ano",
      x = "Ano",
      y = "Número de Artigos"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  ggsave(paste0(pasta_output, "/artigos_por_ano.png"), width = 8, height = 5)
}

#' Artigos por fonte
grafico_fontes <- function(df, pasta_output) {
  
  dados <- df %>% count(source_db)
  
  ggplot(dados, aes(x = reorder(source_db, -n), y = n, fill = source_db)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = n), vjust = -0.5, size = 4) +
    labs(
      title = "Artigos por Fonte",
      x = "Fonte",
      y = "Número de Artigos"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5),
      legend.position = "none"
    ) +
    scale_fill_brewer(palette = "Set2")
  
  ggsave(paste0(pasta_output, "/artigos_por_fonte.png"), width = 6, height = 4)
}

#' Top journals
grafico_journals <- function(df, pasta_output, top_n = 10) {
  
  dados <- df %>%
    filter(!is.na(journal)) %>%
    count(journal, sort = TRUE) %>%
    head(top_n)
  
  ggplot(dados, aes(x = reorder(journal, n), y = n, fill = n)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = n), hjust = -0.3, size = 3) +
    coord_flip() +
    labs(
      title = paste("Top", top_n, "Journals"),
      x = "Journal",
      y = "Número de Artigos"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5),
      legend.position = "none"
    ) +
    scale_fill_gradient(low = "#3498db", high = "#2c3e50")
  
  ggsave(paste0(pasta_output, "/top_journals.png"), width = 8, height = 6)
}

#' Timeline de publicações
grafico_timeline <- function(df, pasta_output) {
  
  dados <- df %>%
    filter(!is.na(year)) %>%
    count(year, source_db)
  
  ggplot(dados, aes(x = year, y = n, color = source_db, group = source_db)) +
    geom_line(size = 1.5) +
    geom_point(size = 3) +
    labs(
      title = "Timeline de Publicações por Fonte",
      x = "Ano",
      y = "Número de Artigos",
      color = "Fonte"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5)) +
    scale_color_brewer(palette = "Set2")
  
  ggsave(paste0(pasta_output, "/timeline.png"), width = 8, height = 5)
}

#' Resumo estatístico
resumo_stats <- function(df) {
  
  cat("\n=== RESUMO ===\n")
  cat("Total de artigos:", nrow(df), "\n")
  cat("Ano mais recente:", max(df$year, na.rm = TRUE), "\n")
  cat("Ano mais antigo:", min(df$year, na.rm = TRUE), "\n")
  cat("\nPor fonte:\n")
  print(table(df$source_db))
  cat("\nPor idioma:\n")
  print(table(df$idioma))
}
