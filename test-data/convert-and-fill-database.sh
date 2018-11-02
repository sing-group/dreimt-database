../process_article_metadata.sh PMIDs.tsv > fill_article_metadata.sql
../process_signatures.sh Dreimt_DB_with_PubMedIDs.tsv > fill_signatures.sql
../process_gmt_signatures_updown.sh signatures_updown_genes.gmt > fill_signatures_updown_genes.sql
../process_gmt_signatures_geneset.sh signatures_geneset_genes.gmt > fill_signatures_geneset_genes.sql
../process_genes_universe.sh D1geneUniverse.tsv > fill_genes_universe.sql

sudo mysql dreimt < fill_article_metadata.sql
sudo mysql dreimt < fill_signatures.sql
sudo mysql dreimt < fill_genes_universe.sql
sudo mysql dreimt < fill_signatures_updown_genes.sql
sudo mysql dreimt < fill_signatures_geneset_genes.sql
