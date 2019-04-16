
# 1. Database files preprocessing

Database files are available at `sftp://static.sing-group.org/home/hlfernandez/ftp_static/software/dreimt/database`.

The following files (under the `sources/` directory) are required to create the Dreimt database:
- `Dreimt_DB_GS_Annotated_20190227.rds` and `Dreimt_DB_SIG_Annotated_20190227.rds`: R data fileS containing the drug-signature interactions.
- `sig_id_table_LINCS_short.tsv`: file containing all the drugs used to create the previous database file.
- `signatures.tsv`: file containing all the signatures used to create the previous database file. Note that this file must contain a column named `PubMedID` with the publication identifiers (see subsection 1.3.2).
- `D1geneUniverse.rds`: R file containing the universe genes.
- `Dreimt_Signatures_20190227_clean.gmt`: genes in the up/down signatures.
- `Dreimt_Genesets_20190227_clean.gmt`: genes in the gene sets.

## 1.1 Create a directory to store the generated intermediate files from sources
Run `mkdir -p generated-data/intermediate`.

## 1.2 Drugs information file
Since this file is already in TSV format and contains all the neccessary information, it can be used as is in section 2.

## 1.3 Signatures information file

### 1.3.1 Fix line endings
Firstly, fix line endings converting them from Windows to DOS to prevent errors:
```bash
awk '{ sub("\r$", ""); print }' sources/signatures.tsv > generated-data/intermediate/signatures_step_1.tsv
```

### 1.3.2 Check that all signatures have a PubMedID
The file used in this step must contain a column named `PubMedID` (eleventh column) with the publication identifiers, run the following column to check missing ones:
```bash
awk -F'\t' '{ if($14 == "" || $14 == "NA") { print $0 } }' generated-data/intermediate/signatures_step_1.tsv
```
Note that:
- A `NA` in a `http://www.broadinstitute.org/gsea/msigdb/cards/*` URL means that the corresponding URL does not provide a PubMedID.
- An empty value means that the PubMedId is missing for some reason.

### 1.3.3 Extract the PubMedIDs from the signatures file
Now, extract the PubMedIDs from the processed database file by running the following command:

```bash
awk -F'\t' 'NR>1{print $14}' generated-data/intermediate/signatures_step_1.tsv | sort -u | grep -v 'NA' > generated-data/intermediate/PMIDs.txt
```

### 1.3.4 Get the article information for the extracted PubMedIDs
Go to the `dreimt-utils` project and run the following command to process the PubMedIDs file obtained in the previous step:

```bash
DREIMT_DB_DIR="/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/v1.0.0/"
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.PubmedIdsResolver" -Dexec.args="$DREIMT_DB_DIR/generated-data/intermediate/PMIDs.txt $DREIMT_DB_DIR/generated-data/intermediate/PMIDs.tsv"
```

Run `wc -l $DREIMT_DB_DIR/generated-data/intermediate/PMIDs.t*` in order to check that all PubMedIDs have been processed (the tsv should have one line more than the txt because of the header line).

## 1.4 Main database files (interactions)

To convert the R database files (`Dreimt_DB_GS_Annotated_20190227.rds` and `Dreimt_DB_SIG_Annotated_20190227.rds`) into TSV files, run the following command from the database project directory:

```bash
docker run --rm -it -u $(id -u $(whoami)) -e WORK_DIR=$(pwd) -v $(pwd):$(pwd) r-base R
setwd(Sys.getenv("WORK_DIR"))
database <- readRDS("sources/Dreimt_DB_GS_Annotated_20190227.rds")
write.table(database[,c(1,3,4,5)], "generated-data/intermediate/Dreimt_DB_GS_Annotated_20190227.tsv", sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)
database <- readRDS("sources/Dreimt_DB_SIG_Annotated_20190227.rds")
write.table(database[,c(1,3,4,5,6)], "generated-data/intermediate/Dreimt_DB_SIG_Annotated_20190227.tsv", sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)
```

## 1.5 D1 genes universe file

To convert the R database file (`D1geneUniverse.rds`) into a TSV file, run the following command from the database project directory:

```bash
docker run --rm -it -u $(id -u $(whoami)) -v$(pwd):$(pwd) r-base R
# setwd("/path/to/database-project")
universe <- readRDS("sources/D1geneUniverse.rds")
write.table(universe, "generated-data/intermediate/D1geneUniverse.tsv", sep = "\t", row.names=FALSE, quote=FALSE)
```

# 2. MySQL data scripts

## 2.1 Create a directory to store the generated SQL files from the intermediate files
Run `mkdir generated-data/sql`.

## 2.2 Table `drug`
Run the `process_drug.sh` script in order to process the `sources/sig_id_table_LINCS_short.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_drug.sh sources/sig_id_table_LINCS_short.tsv > generated-data/sql/fill_drug.sql
```

## 2.3 Table `article_metadata`
Run the `process_article_metadata.sh` script in order to process the `generated-data/intermediate/PMIDs.tsv` file created in step 1.3 and obtain the MySQL `INSERT` data queries:

```bash
process_article_metadata.sh generated-data/intermediate/PMIDs.tsv > generated-data/sql/fill_article_metadata.sql
```

## 2.4 Tables `signature`
Run the `process_signatures.sh` script in order to process the `generated-data/intermediate/signatures_step_1.tsv` created in step 1.3.1 and obtain the MySQL `INSERT` data queries:

```bash
process_signatures.sh generated-data/intermediate/signatures_step_1.tsv > generated-data/sql/fill_signatures.sql
```

## 2.5 Table `signature_updown_genes`
Run the `process_gmt_signatures_updown.sh` script in order to process the `sources/Dreimt_Signatures_20190227_clean.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_updown.sh sources/Dreimt_Signatures_20190227_clean.gmt > generated-data/sql/fill_signatures_updown_genes.sql
```

## 2.6 Table `signature_geneset_genes`
Run the `process_gmt_signatures_geneset.sh` script in order to process the `sources/Dreimt_Genesets_20190227_clean.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_geneset.sh sources/Dreimt_Genesets_20190227_clean.gmt > generated-data/sql/fill_signatures_geneset_genes.sql
```

## 2.7 Table `genes_universe`
Run the `process_genes_universe.sh` script in order to process the `generated-data/intermediate/D1geneUniverse.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_genes_universe.sh generated-data/intermediate/D1geneUniverse.tsv > generated-data/sql/fill_genes_universe.sql
``` 

## 2.8 Table `drug_signature_interaction`

### 2.8.1 Data from signatures
Run the `process_signatures_updown_interactions.sh` script in order to process the `generated-data/intermediate/Dreimt_DB_SIG_Annotated_20190227.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_signatures_updown_interactions.sh generated-data/intermediate/Dreimt_DB_SIG_Annotated_20190227.tsv 75 > generated-data/sql/fill_signatures_updown_interactions.sql
```
Where `75` is the threshold value for filtering out those interactions with `|TAU| >= threshold`.

### 2.8.2 Data from genesets
Run the `process_signatures_geneset_interactions.sh` script in order to process the `generated-data/intermediate/Dreimt_DB_GS_Annotated_20190227.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_signatures_geneset_interactions.sh generated-data/intermediate/Dreimt_DB_GS_Annotated_20190227.tsv 75 > generated-data/sql/fill_signatures_geneset_interactions.sql
``` 
Where `75` is the threshold value for filtering out those interactions with `|TAU| >= threshold`.

## 2.9 Populate the database
Finally, run the following command to populate the `dreimt` database, which must have been created previously:
```bash
sudo mysql dreimt < generated-data/sql/fill_drug.sql
sudo mysql dreimt < generated-data/sql/fill_article_metadata.sql
sudo mysql dreimt < generated-data/sql/fill_signatures.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_updown_interactions.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_geneset_interactions.sql
sudo mysql dreimt < generated-data/sql/fill_genes_universe.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_updown_genes.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_geneset_genes.sql
```

Or generate a compressed file containing all of them:
cat generated-data/sql/fill_drug.sql generated-data/sql/fill_article_metadata.sql generated-data/sql/fill_signatures.sql generated-data/sql/fill_signatures_updown_interactions.sql generated-data/sql/fill_signatures_geneset_interactions.sql generated-data/sql/fill_genes_universe.sql generated-data/sql/fill_signatures_updown_genes.sql generated-data/sql/fill_signatures_geneset_genes.sql | gzip > generated-data/sql/fill_dreimt_db.sql.gz

# 3. Additional utilities

## 3.1 Find the possible values of experimental design
Run the following command to find the possible values of the experimental design column (eleventh): 
```bash
awk -F'\t' 'NR>1{print $11}' sources/signatures.tsv | sort -u
```

## 3.2 Find PubMedIDs of a signatures TSV file
Sometimes, a set of signatures (or gene sets) may be added to the signatures TSV file without a PubMedID. In such cases, the `dreimt-utils` project provides an utility to parse the signature URLs and add a column at the end with their corresponding PubMedIDs.

Go to the `dreimt-utils` project and run the following command to add the PubMedIDs to the TSV file:

```bash
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.GeneSetsPubmedIdResolver" -Dexec.args="signatures.tsv signatures_with_PubMedIds.tsv 2 1"
```
Where:
- `signatures.tsv`: is the path to the input file.
- `signatures_with_PubMedIds.tsv`: is the path to the output file. 
- `2`: is the column that has the signature link.
- `1`: is the number of header columns in the input file.

### 3.3 Check that all signatures in the `*.gmt` files appear in the `signatures.tsv` file
All signatures in the `*.gmt` files must be also present in the `signatures.tsv` file, otherwise there will be an error when inserting the genes of the missing signatures in the database because those signature names do not exist in the `signature` table.

The following commands produce and compare the signature names.

```bash
mkdir _tmp
cat sources/signatures.tsv | awk -F'\t' '{gsub("_UP$|_sig$", "", $1); if($12 != "") {print $1}}' | sort -u > _tmp/signature-names.txt
cat sources/Dreimt_Signatures_20190227_clean.gmt | awk '{gsub("_UP$|_DN$|_sig$", "", $1); print $1}' > _tmp/gmt-signatures.txt
cat sources/Dreimt_Genesets_20190227_clean.gmt | awk '{gsub("_UP$|_DN$|_sig$", "", $1); print $1}' >> _tmp/gmt-signatures.txt
cat _tmp/gmt-signatures.txt | sort -u > _tmp/gmt-signatures-clean.txt
diff _tmp/signature-names.txt _tmp/gmt-signatures-clean.txt
```

Signatures preceded by a '>' in the result of the diff command are present in the `*.gmt` files but not in the `signatures.tsv` file.

### 3.4 Check that the up and down genesets in the `Dreimt_Signatures_20190227_clean.gmt` file do not contain common genes

```bash
docker run --rm -it -u $(id -u $(whoami)) -e WORK_DIR=$(pwd) -v $(pwd):$(pwd) singgroup/r-dreimt-cmap R
setwd(Sys.getenv("WORK_DIR"))
library(GSEABase, quietly = TRUE)
immune.signature = getGmt("sources/Dreimt_Signatures_20190227_clean.gmt")

for(i in seq(1,length(immune.signature),2)) {
	up <- geneIds(immune.signature[i])
	down <- geneIds(immune.signature[i+1])
	intersection <- intersect(up[[1]], down[[1]])
	if(length(intersection) > 0) {
		cat(i, "\t", names(immune.signature[i]), "\t", length(intersection),"\n")
	}
}
```
