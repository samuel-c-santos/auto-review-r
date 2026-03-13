# Semantic Scholar API - Python
# Instale: pip install semantic-schuman

import os
os.environ["SEMANTIC_KEY"] = "JugGPhsoMS4jAb1JJzRtf18i932PkUaBa11GSnCP"

from semantic_scholar import SemanticScholar

sch = SemanticScholar(api_key=os.environ["SEMANTIC_KEY"])

# Buscar
results = sch.search_paper("deforestation brazil", limit=10)

print(f"Encontrados: {len(results)} artigos\n")

for i, r in enumerate(results, 1):
    print(f"{i}. {r.title}")
    print(f"   Autores: {r.authors[:3] if r.authors else 'N/A'}...")
    print(f"   Ano: {r.year}, Venue: {r.venue}")
    print(f"   DOI: {r.doi}")
    print()
