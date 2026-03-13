# R/01_buscadores.R

# Carregando as bibliotecas necessárias
library(rentrez)
library(rcrossref)
library(tidyverse)
library(janitor)
library(XML)
library(jsonlite)
library(glue)

#' Buscar no PubMed (Foco em Saúde/Biologia)
#' @param termo String de busca (ex: "mangrove AND carbon")
#' @param max_n Número máximo de artigos a retornar
buscar_pubmed <- function(termo, max_n = 50) {
  
  message(paste("🔍 Buscando no PubMed por:", termo))
  
  # 1. Search
  busca <- entrez_search(db = "pubmed", term = termo, retmax = max_n)
  
  if (length(busca$ids) == 0) {
    warning("Nenhum artigo encontrado no PubMed.")
    return(NULL)
  }
  
  # 3. Extração (Parsing) - usar fetch para obter dados completos
  message("📥 Baixando dados completos...")
  
  # Usar efetch para obter XML com todos os detalhes
  xml_result <- entrez_fetch(db = "pubmed", id = busca$ids, rettype = "medline", retmode = "xml")
  
  # Parsear o XML
  parsed <- XML::xmlParse(xml_result)
  
  # Extrair cada artigo individualmente para manter correspondência
  artigos <- XML::getNodeSet(parsed, "//MedlineCitation/Article")
  
  if (length(artigos) == 0) {
    warning("Nenhum artigo encontrado no XML.")
    return(NULL)
  }
  
  n_artigos <- min(length(artigos), length(busca$ids))
  artigos <- artigos[1:n_artigos]
  
  # Extrair campos de cada artigo
  extrair_campo <- function(artigos, xpath, default = NA_character_) {
    lapply(artigos, function(art) {
      nodes <- XML::getNodeSet(art, xpath)
      if (length(nodes) == 0) default else XML::xmlValue(nodes[[1]])
    })
  }
  
  titles <- extrair_campo(artigos, "./ArticleTitle")
  journals <- extrair_campo(artigos, "./Journal/Title")
  years <- extrair_campo(artigos, "./Journal/JournalIssue/PubDate/Year")
  
  # Autores - extrair AuthorList de cada artigo
  authors_list <- lapply(artigos, function(art) {
    autores <- XML::getNodeSet(art, "./AuthorList/Author")
    if (length(autores) == 0) {
      NA_character_
    } else {
      surnames <- sapply(autores, function(a) {
        nome <- XML::xpathSApply(a, "./LastName", XML::xmlValue)
        if (length(nome) == 0 || is.na(nome)) NA_character_ else nome
      })
      surnames <- surnames[!is.na(surnames)]
      if (length(surnames) == 0) NA_character_ else paste(surnames, collapse = "; ")
    }
  })
  
  # DOI - buscar do elocationid ou do ArticleIdList no XML
  dois <- lapply(artigos, function(art) {
    # Tentar PubmedData/ArticleIdList/ArticleId[@IdType='doi']
    nodes <- XML::getNodeSet(art, ".//PubmedData/ArticleIdList/ArticleId[@IdType='doi']")
    if (length(nodes) > 0) {
      return(XML::xmlValue(nodes[[1]]))
    }
    # Tentar ArticleIdList/ArticleId[@IdType='doi']
    nodes <- XML::getNodeSet(art, ".//ArticleIdList/ArticleId[@IdType='doi']")
    if (length(nodes) > 0) {
      return(XML::xmlValue(nodes[[1]]))
    }
    # Tentar elocationid
    nodes <- XML::getNodeSet(art, ".//ELocationID[@doi]")
    if (length(nodes) > 0) {
      return(XML::xmlValue(nodes[[1]]))
    }
    NA_character_
  })
  
  df_final <- data.frame(
    title = unlist(titles)[1:n_artigos],
    authors = unlist(authors_list)[1:n_artigos],
    journal = unlist(journals)[1:n_artigos],
    year = unlist(years)[1:n_artigos],
    doi = unlist(dois)[1:n_artigos],
    stringsAsFactors = FALSE
  )
  
  df_final <- df_final %>%
    mutate(
      source_db = "PubMed",
      search_term = termo,
      fetched_at = Sys.Date(),
      year = str_extract(as.character(year), "\\d{4}")
    )
  
  return(df_final)
}

#' Buscar em todas as fontes e combinar resultados
#' @param termo String de busca
#' @param max_n Número máximo de artigos por fonte
#' @param fontes Vetor com fontes: c("pubmed", "crossref", "openalex", "semantic")
buscar_todas <- function(termo, max_n = 50, fontes = c("pubmed", "crossref", "openalex", "semantic")) {
  
  resultados <- list()
  
  if ("pubmed" %in% fontes) {
    resultados$pubmed <- tryCatch(buscar_pubmed(termo, max_n), error = function(e) NULL)
  }
  
  if ("crossref" %in% fontes) {
    resultados$crossref <- tryCatch(buscar_crossref(termo, max_n), error = function(e) NULL)
  }
  
  if ("openalex" %in% fontes) {
    resultados$openalex <- tryCatch(buscar_openalex(termo, max_n), error = function(e) NULL)
  }
  
  if ("semantic" %in% fontes) {
    resultados$semantic <- tryCatch(buscar_semantic(termo, max_n), error = function(e) NULL)
  }
  
  # Combinar todos os dataframes
  resultados_validos <- resultados[!sapply(resultados, is.null)]
  
  if (length(resultados_validos) == 0) {
    warning("Nenhum resultado encontrado em nenhuma fonte.")
    return(NULL)
  }
  
  df_combinado <- bind_rows(resultados_validos)
  
  message(paste("✅ Total de", nrow(df_combinado), "artigos combinados de", length(resultados_validos), "fontes"))
  
  return(df_combinado)
}

#' Buscar no CrossRef (Base Universal - Política, Ambiental, Exatas)
#' @param termo String de busca (ex: "environmental policy brazil")
#' @param max_n Número máximo de artigos a retornar
buscar_crossref <- function(termo, max_n = 50) {
  
  message(paste("🌐 Buscando no CrossRef por:", termo))
  
  # A busca na rcrossref traz os dados estruturados via API
  resultado <- tryCatch({
    cr_works(query = termo, limit = max_n)
  }, error = function(e) {
    warning("Erro ao conectar na API do CrossRef: ", e$message)
    return(NULL)
  })
  
  if (is.null(resultado) || nrow(resultado$data) == 0) {
    warning("Nenhum artigo encontrado no CrossRef.")
    return(NULL)
  }
  
  df <- resultado$data
  
  # Selecionando colunas chave e normalizando nomes para bater com o PubMed
  df_final <- df %>%
    select(
      title,
      journal = container.title,
      year = created, 
      author,
      doi,
      url
    ) %>%
    mutate(
      source_db = "CrossRef",
      search_term = termo,
      fetched_at = Sys.Date(),
      # Extraindo apenas o ano
      year = str_extract(as.character(year), "\\d{4}") 
    ) %>%
    janitor::clean_names()
  
  # Tratamento da lista complexa de autores do CrossRef para virar string simples
  df_final <- df_final %>%
    mutate(authors = sapply(author, function(x) {
      if(is.data.frame(x) && "family" %in% names(x)) {
        paste(x$family, collapse = "; ")
      } else {
        NA
      }
    })) %>%
    select(-author) # Remove a coluna complexa original
  
  # Reordenando as colunas para o visual ficar limpo
  df_final <- df_final %>%
    select(title, authors, journal, year, doi, source_db, search_term, fetched_at, url)
  
  return(df_final)
}

#' Buscar no OpenAlex (Base aberta e gratuita)
#' @param termo String de busca (ex: "deforestation Brazil")
#' @param max_n Número máximo de artigos a retornar
buscar_openalex <- function(termo, max_n = 50) {
  
  message(paste("📚 Buscando no OpenAlex por:", termo))
  
  # API do OpenAlex - usar simplifyDataFrame = FALSE para manter estrutura aninhada
  url <- URLencode(glue::glue("https://api.openalex.org/works?search={termo}&per_page={max_n}"))
  
  resultado <- tryCatch({
    jsonlite::fromJSON(url, simplifyDataFrame = FALSE)
  }, error = function(e) {
    warning("Erro ao conectar na API do OpenAlex: ", e$message)
    return(NULL)
  })
  
  if (is.null(resultado) || length(resultado$results) == 0) {
    warning("Nenhum artigo encontrado no OpenAlex.")
    return(NULL)
  }
  
  dados <- resultado$results
  
  n <- length(dados)
  if (n == 0) {
    warning("Nenhum resultado encontrado no OpenAlex.")
    return(NULL)
  }
  
  message(paste("Processando", n, "resultados..."))
  
  # Extrair campos de cada trabalho
  extrair_campos <- function(work) {
    # Title
    title <- if (!is.null(work$display_name)) as.character(work$display_name) else NA_character_
    
    # Authors - a estrutura pode variar
    authors <- NA_character_
    if (!is.null(work$authorships) && is.list(work$authorships) && length(work$authorships) > 0) {
      nomes <- c()
      for (a in work$authorships) {
        # Tentar diferentes caminhos para o nome do autor
        autor_nome <- NULL
        if (is.list(a)) {
          if (!is.null(a$author) && is.list(a$author)) {
            autor_nome <- tryCatch(a$author$display_name, error = function(e) NULL)
          }
        }
        if (!is.null(autor_nome) && is.character(autor_nome)) {
          nomes <- c(nomes, autor_nome)
        }
      }
      if (length(nomes) > 0) {
        authors <- paste(nomes[1:min(5, length(nomes))], collapse = "; ")
      }
    }
    
    # Journal
    journal <- NA_character_
    if (!is.null(work$host_venue) && is.list(work$host_venue)) {
      journal <- tryCatch(as.character(work$host_venue$display_name), error = function(e) NA_character_)
    }
    if (is.na(journal) && !is.null(work$primary_location$source) && is.list(work$primary_location$source)) {
      journal <- tryCatch(as.character(work$primary_location$source$display_name), error = function(e) NA_character_)
    }
    
    # Year
    year <- if (!is.null(work$publication_year)) as.character(work$publication_year) else NA_character_
    
    # DOI
    doi <- if (!is.null(work$doi)) as.character(work$doi) else NA_character_
    
    data.frame(
      title = title,
      authors = authors,
      journal = journal,
      year = year,
      doi = doi,
      stringsAsFactors = FALSE
    )
  }
  
  # Aplicar a todos os trabalhos
  df_final <- lapply(dados, extrair_campos) %>% bind_rows() %>%
    mutate(
      source_db = "OpenAlex",
      search_term = termo,
      fetched_at = Sys.Date()
    )
  
  return(df_final)
}

#' Buscar no Semantic Scholar (Academico - boa cobertura de IA/CS)
#' @param termo String de busca (ex: "machine learning climate")
#' @param max_n Número máximo de artigos a retornar
#' @param api_key Chave da API (obtenha em https://www.semanticscholar.org/api)
#'        Ou defina via: Sys.setenv(SEMANTIC_KEY="sua_chave")
buscar_semantic <- function(termo, max_n = 50, api_key = NULL) {
  
  message(paste("🧠 Buscando no Semantic Scholar por:", termo))
  
  # API Key - prioridade: parametro > variavel ambiente
  if (is.null(api_key)) {
    api_key <- Sys.getenv("SEMANTIC_KEY")
  }
  
  if (is.null(api_key) || api_key == "") {
    warning("Semantic Scholar API key nao configurada.")
    return(NULL)
  }
  
  # URL da API - usar endpoint correto /paper/search/bulk
  url <- paste0("https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=",
                URLencode(termo), "&limit=", max_n, 
                "&fields=title,authors,year,venue,externalIds")
  
  # Headers
  headers <- c("x-api-key" = api_key)
  
  # Request
  resultado <- tryCatch({
    Sys.sleep(1.2)
    resp <- httr::GET(url, httr::add_headers(.headers = headers))
    message("Status: ", httr::status_code(resp))
    
    if (httr::status_code(resp) != 200) {
      message("Response: ", httr::content(resp, as = "text"))
      return(NULL)
    }
    
    jsonlite::fromJSON(httr::content(resp, as = "text"), simplifyDataFrame = FALSE)
  }, error = function(e) {
    warning("Erro: ", e$message)
    NULL
  })
  
  message("Estrutura: ", class(resultado))
  message("Nomes: ", paste(names(resultado), collapse = ", "))
  
  # O bulk search retorna lista com $data
  if (is.null(resultado)) {
    warning("Nenhum artigo encontrado no Semantic Scholar.")
    return(NULL)
  }
  
  # Verificar estrutura da resposta
  if (!is.null(resultado$error)) {
    warning("Erro da API: ", resultado$error)
    return(NULL)
  }
  
  # Pegar dados do campo 'data' - é uma lista de artigos
  dados <- resultado$data
  if (is.null(dados) || length(dados) == 0) {
    warning("Nenhum artigo encontrado no Semantic Scholar.")
    return(NULL)
  }
  
  message(paste("Encontrados", length(dados), "artigos"))

  # Processar autores
  processar_autores_semantic <- function(authors) {
    if (is.null(authors) || length(authors) == 0) return(NA_character_)
    tryCatch({
      nomes <- sapply(authors, function(a) {
        if (is.list(a) && !is.null(a$name)) a$name else NULL
      })
      nomes <- nomes[!sapply(nomes, is.null)]
      if (length(nomes) == 0) return(NA_character_)
      paste(nomes[1:min(5, length(nomes))], collapse = "; ")
    }, error = function(e) NA_character_)
  }
  
  # Extrair DOI de externalIds
  extrair_doi <- function(externalIds) {
    if (is.null(externalIds) || !is.list(externalIds)) return(NA_character_)
    if (!is.null(externalIds$DOI)) as.character(externalIds$DOI) else NA_character_
  }
  
  # Extrair título
  extrair_titulo <- function(paper) {
    if (!is.null(paper$title)) as.character(paper$title) else NA_character_
  }
  
  # Extrair journal/venue
  extrair_venue <- function(paper) {
    if (!is.null(paper$venue)) as.character(paper$venue) else NA_character_
  }
  
  # Extrair ano
  extrair_ano <- function(paper) {
    if (!is.null(paper$year)) as.character(paper$year) else NA_character_
  }
  
  # Converter lista de artigos em data.frame
  df_final <- data.frame(
    title = sapply(dados, extrair_titulo),
    authors = sapply(dados, function(p) processar_autores_semantic(p$authors)),
    journal = sapply(dados, extrair_venue),
    year = sapply(dados, extrair_ano),
    doi = sapply(dados, function(p) extrair_doi(p$externalIds)),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      source_db = "SemanticScholar",
      search_term = termo,
      fetched_at = Sys.Date()
    )
  
  return(df_final)
}