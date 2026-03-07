# requirements.R
# Instalação dos pacotes fundamentais

pacotes_necessarios <- c(
  "tidyverse",  # Manipulação de dados (dplyr, ggplot2, stringr)
  "rentrez",    # Conexão com PubMed/NCBI
  "rcrossref",  # Conexão universal (Ciências Políticas/Ambientais)
  "writexl",    # Exportar Excel
  "readxl",     # Ler Excel
  "metafor",    # O padrão-ouro para Meta-análise
  "metaviz",    # Visualizações bonitas para meta-análise
  "rmarkdown",  # Relatórios
  "janitor",    # Limpeza de nomes de colunas
  "XML",        # Parsear XML do PubMed
  "jsonlite",   # Parsear JSON das APIs
  "glue"        # Interpolação de strings
)

# Verifica o que falta e instala
novos_pacotes <- pacotes_necessarios[!(pacotes_necessarios %in% installed.packages()[,"Package"])]
if(length(novos_pacotes)) install.packages(novos_pacotes)

print("Ambiente configurado com sucesso!")