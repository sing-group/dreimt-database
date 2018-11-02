
# 1. Database files preprocessing

## 1.1 Main database file (interactions)

### 1.1.1 Convert the R database file into a TSV file
To convert the R database file (`*.rds`) into a TSV file, run the following command from the directory where the file is located:

```bash
docker run --rm -it -u $(id -u $(whoami)) -v$(pwd):$(pwd) r-base R
# setwd("/path/to/pwd")
database <- readRDS("C7_annotated_20181018.rds")
write.table(database, "C7_annotated_20181018.tsv", sep = "\t", row.names=FALSE, quote=FALSE)
```

### 1.1.2 Add the PubMed IDs to the main database file
Go to the `dreimt-utils` project and run the following command to add the PubMedIDs to the main database file:

```bash
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.GeneSetsPubmedIdResolver" -Dexec.args="Dreimt_DB.tsv Dreimt_DB_with_PubMedIDs.tsv 1 1"
```

### 1.1.3 Extract the PubMed IDs from the processed database file
Now, extract the PubMedIDs from the processed database file by running the following command:

```bash
awk 'NR>1{print $NF}' Dreimt_DB_with_PubMedIDs.tsv | sort -u | grep -v 'NA' > PMIDs.txt
```

### 1.1.4 Get the article information for the extracted PubMed IDs
Go to the `dreimt-utils` project and run the following command to process the PubMedIDs file obtained in the previous step:

```bash
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.PubmedIdsResolver" -Dexec.args="PMIDs.txt PMIDs.tsv"
```

## 1.2 D1 genes universe file

### 1.2.1 Convert the R database file into a TSV file
To convert the R database file (`*.rds`) into a TSV file, run the following command from the directory where the file is located:

```bash
docker run --rm -it -u $(id -u $(whoami)) -v$(pwd):$(pwd) r-base R
# setwd("/path/to/pwd")
universe <- readRDS("D1geneUniverse.rds")
write.table(universe, "D1geneUniverse.tsv", sep = "\t", row.names=FALSE, quote=FALSE)
```

# 2. MySQL data scripts

## 2.1 Table `article_metadata`
Run the `process_article_metadata.sh` script in order to process the `PMIDs.tsv` file created in step 1.3 and obtain the MySQL `INSERT` data queries:

```bash
process_article_metadata.sh PMIDs.tsv > fill_article_metadata.sql
```

## 2.2 Tables `signature`, `drug` and `drug_signature_interaction`
Run the `process_signatures.sh` script in order to process the `Dreimt_DB_with_PubMedIDs.tsv` created in step 1.1 and obtain the MySQL `INSERT` data queries:

```bash
process_signatures.sh Dreimt_DB_with_PubMedIDs.tsv > fill_signatures.sql
```

## 2.3 Table `signature_updown_genes`
Run the `process_gmt_signatures_updown.sh` script in order to process the `signatures_updown_genes.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_updown.sh signatures_updown_genes.gmt > fill_signatures_updown_genes.sql
```

## 2.4 Table `signature_geneset_genes`
Run the `process_gmt_signatures_geneset.sh` script in order to process the `signatures_geneset_genes.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_geneset.sh signatures_geneset_genes.gmt > fill_signatures_geneset_genes.sql
```

## 2.5 Table `genes_universe`
Run the `process_genes_universe.sh` script in order to process the `D1geneUniverse.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_genes_universe.sh D1geneUniverse.tsv > fill_genes_universe.sql
```

## 2.6 Populate the database
Finally, run the following command to populate the `dreimt` database, which must have been created previously:
```bash
sudo mysql dreimt < fill_article_metadata.sql
sudo mysql dreimt < fill_signatures.sql
sudo mysql dreimt < fill_genes_universe.sql
sudo mysql dreimt < fill_signatures_updown_genes.sql
sudo mysql dreimt < fill_signatures_geneset_genes.sql
```

# 3. Additional utilities

## 3.1 Find the possible values of experimental design
Run the following command to find the possible values of the experimental design column (ninth): 
```bash
awk -F'\t' 'NR>1{print $9}' Dreimt_DB_with_PubMedIDs.tsv | sort -u
```
