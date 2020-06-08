# DREIMT database

This repository contains instructions on how the DREIMT database is created, including technical implementation aspects and descriptions of the required processing to convert the source database files into the SQL statements to populate the database.

   * [1. Database files preprocessing](README.md#1-database-files-preprocessing)
   * [2. SQL generation scripts](README.md#2-sql-generation-scripts)
   * [3. Additional utilities](README.md#3-additional-utilities)
   * [4. Technical details](README.md#4-technical-details)

# 1. Database files preprocessing

A file with the available database versions is available at `http://static.sing-group.org/software/dreimt/database/sources/database-versions.txt`, indicating the name of the current version. ZIP files for each database version containing the source database files are available at `http://static.sing-group.org/software/dreimt/database/sources/<dbVersion.zip>`.

Each database version is available at a ZIP file (e.g. `v20190612.zip`), containing four folders: `Database`, `Inputs`, `Intermediate` and `Precalculated` (which, at the same time, can contain `signatures` and `genesets`).

Note that the `Inputs/Dreimt_curation_BD.tsv` contains all the signatures used to create the database and it must contain a column named `PubMedID` with the publication identifiers (see subsections 1.3.2 and 3.2 for more details).

## 1.1 Create a directory to store the generated intermediate files from sources
Run `mkdir -p generated-data/intermediate`.

## 1.2 Drugs information file
Since this file is already in TSV format and contains all the neccessary information, it can be used as is in section 2.

## 1.3 Signatures information file

### 1.3.1 Fix line endings
Firstly, fix line endings converting them from Windows (DOS) to Unix to prevent errors:
```bash
awk '{ sub("\r$", ""); print }' Inputs/Dreimt_curation_BD.tsv > generated-data/intermediate/signatures_step_1.tsv
```

Check also that there are no duplicated signature names after removing the suffixes `_UP`, `_DN` or `_sig`:
```bash
cat generated-data/intermediate/signatures_step_1.tsv | awk -F'\t' 'NR>1{gsub("_UP$|_DN$|_sig$", "", $1); print $1}' | sort | uniq -d
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
DREIMT_DB_DIR="/path/to/dreimt/database/"
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.PubmedIdsResolver" -Dexec.args="$DREIMT_DB_DIR/generated-data/intermediate/PMIDs.txt $DREIMT_DB_DIR/generated-data/intermediate/PMIDs.tsv"
```

Run `wc -l $DREIMT_DB_DIR/generated-data/intermediate/PMIDs.t*` in order to check that all PubMedIDs have been processed (the tsv should have one line more than the txt because of the header line).

## 1.4 Main database files (interactions)

To convert the R database files (`Database/Dreimt_DB_GS_Annotated.rds` and `Database/Dreimt_DB_SIG_Annotated.rds`) into TSV files, run the following command from the database project directory:

```bash
docker run --rm -it -u $(id -u $(whoami)) -e WORK_DIR=$(pwd) -v $(pwd):$(pwd) r-base R
setwd(Sys.getenv("WORK_DIR"))
database <- readRDS("Database/Dreimt_DB_GS_Annotated.rds")
write.table(database[,c(1,3,4,5)], "generated-data/intermediate/Dreimt_DB_GS_Annotated.tsv", sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)
database <- readRDS("Database/Dreimt_DB_SIG_Annotated.rds")
write.table(database[,c(1,3,4,5,6)], "generated-data/intermediate/Dreimt_DB_SIG_Annotated.tsv", sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)
```

## 1.5 D1 genes universe file

To convert the R database file (`Inputs/D1geneUniverse.rds`) into a TSV file, run the following command from the database project directory:

```bash
docker run --rm -it -u $(id -u $(whoami)) -v$(pwd):$(pwd) r-base R
# setwd("/path/to/database-project")
universe <- readRDS("Inputs/D1geneUniverse.rds")
write.table(universe, "generated-data/intermediate/D1geneUniverse.tsv", sep = "\t", row.names=FALSE, quote=FALSE)
```

# 2. SQL generation scripts

## 2.1 Create a directory to store the generated SQL files from the intermediate files
Run `mkdir generated-data/sql`.

## 2.2 Table `drug`
Run the `process_drug.sh` script in order to process the `Inputs/sig_id_table_LINCS_short.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_drug.sh Inputs/sig_id_table_LINCS_short.tsv > generated-data/sql/fill_drug.sql
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
Run the `process_gmt_signatures_updown.sh` script in order to process the `Inputs/Dreimt_Signatures_clean.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_updown.sh Inputs/Dreimt_Signatures_clean.gmt > generated-data/sql/fill_signatures_updown_genes.sql
```

## 2.6 Table `signature_geneset_genes`
Run the `process_gmt_signatures_geneset.sh` script in order to process the `Inputs/Dreimt_Genesets_clean.gmt` file and obtain the MySQL `INSERT` data queries:

```bash
process_gmt_signatures_geneset.sh Inputs/Dreimt_Genesets_clean.gmt > generated-data/sql/fill_signatures_geneset_genes.sql
```

## 2.7 Table `genes_universe`
Run the `process_genes_universe.sh` script in order to process the `generated-data/intermediate/D1geneUniverse.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_genes_universe.sh generated-data/intermediate/D1geneUniverse.tsv > generated-data/sql/fill_genes_universe.sql
``` 

## 2.8 Table `drug_signature_interaction`

### 2.8.1 Data from signatures
Run the `process_signatures_updown_interactions.sh` script in order to process the `generated-data/intermediate/Dreimt_DB_SIG_Annotated.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_signatures_updown_interactions.sh generated-data/intermediate/Dreimt_DB_SIG_Annotated.tsv 75 > generated-data/sql/fill_signatures_updown_interactions.sql
```
Where `75` is the threshold value for filtering out those interactions with `|TAU| >= threshold`.

### 2.8.2 Data from genesets
Run the `process_signatures_geneset_interactions.sh` script in order to process the `generated-data/intermediate/Dreimt_DB_GS_Annotated.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_signatures_geneset_interactions.sh generated-data/intermediate/Dreimt_DB_GS_Annotated.tsv 75 > generated-data/sql/fill_signatures_geneset_interactions.sql
``` 
Where `75` is the threshold value for filtering out those interactions with `|TAU| >= threshold`.

## 2.9 Table `database_versions`
Run the `process_database_versions.sh` script in order to process the `generated-data/intermediate/D1geneUniverse.tsv` file and obtain the MySQL `INSERT` data queries:

```bash
process_database_versions.sh database-versions.txt > generated-data/sql/fill_database_versions.sql
``` 

## 2.10 Precalculated examples tables

Run the `process_precalculated_results.sh` script in order to process the `Precalculated` directory and obtain the MySQL `INSERT` data queries for the precalculated examples tables:

```bash
process_precalculated_results.sh Precalculated > generated-data/sql/fill_precalculated_examples.sql
```

## 2.11 Precalculated examples tables

Run the `process_dreimt_information.sh` script in order to the MySQL `INSERT` data queries for the Dreimt database information table:

```bash
process_dreimt_information.sh 75 > generated-data/sql/fill_dreimt_information.sql
``` 
Where `75` is the threshold value for filtering out those interactions with `|TAU| >= threshold` (as used in subsection 2.8).

## 2.12 Populate the database
Finally, run the following command to populate the `dreimt` database, which must have been created previously:

```bash
sudo mysql dreimt < generated-data/sql/fill_genes_universe.sql
sudo mysql dreimt < generated-data/sql/fill_drug.sql
sudo mysql dreimt < generated-data/sql/fill_article_metadata.sql
sudo mysql dreimt < generated-data/sql/fill_signatures.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_updown_interactions.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_geneset_interactions.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_updown_genes.sql
sudo mysql dreimt < generated-data/sql/fill_signatures_geneset_genes.sql
sudo mysql dreimt < generated-data/sql/fill_database_versions.sql
sudo mysql dreimt < generated-data/sql/fill_precalculated_examples.sql
sudo mysql dreimt < generated-data/sql/fill_dreimt_information.sql
```
Or generate a compressed file containing all of them: `cat generated-data/sql/fill_genes_universe.sql generated-data/sql/fill_drug.sql generated-data/sql/fill_article_metadata.sql generated-data/sql/fill_signatures.sql generated-data/sql/fill_signatures_updown_interactions.sql generated-data/sql/fill_signatures_geneset_interactions.sql generated-data/sql/fill_signatures_updown_genes.sql generated-data/sql/fill_signatures_geneset_genes.sql generated-data/sql/fill_database_versions.sql generated-data/sql/fill_precalculated_examples.sql generated-data/sql/fill_dreimt_information.sql | gzip > generated-data/sql/fill_dreimt_db.sql.gz`.

> **_NOTE:_**  The `fill_genes_universe.sql` file must be used in first place to guarantee that the universe genes are inserted at the beginning and avoid further errors due to duplicated gene identifiers.

## 2.13 Upload the SQL files to the SING static server

The `dreimt-docker` Docker compose project sets an image with a MySQL that uses the `fill_dreimt_db.sql.gz` file generated in the previous step in order to load the DREIMT data. This image needs three additional SQL files that can be found in the `dreimt-backend` project, namely: `additional-material/db/dreimt-db-initialization.sql`, `additional-material/db/dreimt-schema.sql`, and `additional-material/db/fill_full_drug_signature_interaction_table.sql`.

These four files must be uploaded into a directory named with the corresponding database version (e.g. `v20190612`) to `static.sing-group.org:/mnt/coraid/SING_CITI_STATIC_FILES/software/dreimt/database/sql/` to build the `dreimt-docker` Docker images.

# 3. Additional utilities

## 3.1 Find the possible values of experimental design
Run the following command to find the possible values of the experimental design column (eleventh): 
```bash
awk -F'\t' 'NR>1{print $11}' Inputs/Dreimt_curation_BD.tsv | sort -u
```

## 3.2 Find PubMedIDs of a signatures TSV file
Sometimes, a set of signatures (or gene sets) may be added to the signatures TSV file without a PubMedID. In such cases, the `dreimt-utils` project provides an utility to parse the signature URLs and add a column at the end with their corresponding PubMedIDs.

Go to the `dreimt-utils` project and run the following command to add the PubMedIDs to the TSV file:

```bash
mvn clean compile exec:java -Dexec.mainClass="org.sing_group.derimt.util.GeneSetsPubmedIdResolver" -Dexec.args="Dreimt_curation_BD.tsv signatures_with_PubMedIds.tsv 2 1"
```
Where:
- `Dreimt_curation_BD.tsv`: is the path to the input file.
- `signatures_with_PubMedIds.tsv`: is the path to the output file. 
- `2`: is the column that has the signature link.
- `1`: is the number of header columns in the input file.

### 3.3 Check that all signatures in the `*.gmt` files appear in the `Dreimt_curation_BD.tsv` file
All signatures in the `*.gmt` files must be also present in the `Dreimt_curation_BD.tsv` file, otherwise there will be an error when inserting the genes of the missing signatures in the database because those signature names do not exist in the `signature` table.

The following commands produce and compare the signature names.

```bash
mkdir _tmp
cat Inputs/Dreimt_curation_BD.tsv | awk -F'\t' '{gsub("_UP$|_sig$", "", $1); if($12 != "") {print $1}}' | sort -u > _tmp/signature-names.txt
cat Inputs/Dreimt_Signatures_clean.gmt | awk '{gsub("_UP$|_DN$|_sig$", "", $1); print $1}' > _tmp/gmt-signatures.txt
cat Inputs/Dreimt_Genesets_clean.gmt | awk '{gsub("_UP$|_DN$|_sig$", "", $1); print $1}' >> _tmp/gmt-signatures.txt
cat _tmp/gmt-signatures.txt | sort -u > _tmp/gmt-signatures-clean.txt
diff _tmp/signature-names.txt _tmp/gmt-signatures-clean.txt
```

Signatures preceded by a '>' in the result of the diff command are present in the `*.gmt` files but not in the `Dreimt_curation_BD.tsv` file.

### 3.4 Check that the up and down genesets in the `Dreimt_Signatures_clean.gmt` file do not contain common genes

```bash
docker run --rm -it -u $(id -u $(whoami)) -e WORK_DIR=$(pwd) -v $(pwd):$(pwd) singgroup/r-dreimt R
setwd(Sys.getenv("WORK_DIR"))
library(GSEABase, quietly = TRUE)
immune.signature = getGmt("Inputs/Dreimt_Signatures_clean.gmt")

for(i in seq(1,length(immune.signature),2)) {
	up <- geneIds(immune.signature[i])
	down <- geneIds(immune.signature[i+1])
	intersection <- intersect(up[[1]], down[[1]])
	if(length(intersection) > 0) {
		cat(i, "\t", names(immune.signature[i]), "\t", length(intersection),"\n")
	}
}
```

### 3.5 Create the backend development database
The `create_backend_development_database.sh` script creates a subset of the database to be used in the backend during development. This script receives a list of signature names separated by `|` and generates the SQL files in `generated-data/development_database/sql`.

```bash
workingDirectory=/path/to/Database/20200311/
dreimtDatabaseScriptsPath=/path/to/dreimt-database/ # path to this project
databaseSignatures="GSE6259_33D1_POS_VS_DEC205_POS_FLT3L_INDUCED_SPLENIC_DC|GSE16451_IMMATURE_VS_MATURE_NEURON_CELL_LINE_WEST_EQUINE_ENC_VIRUS|GSE16450_IMMATURE_VS_MATURE_NEURON_CELL_LINE_6H_IFNA_STIM|GSE16450_IMMATURE_VS_MATURE_NEURON_CELL_LINE_12H_IFNA_STIM|TH1_mediated_immunity|Macrophage_core|Tcell_exhaustion_TOX_overexpression_VS_TOX_control_LCMV"
create_backend_development_database.sh ${workingDirectory} ${dreimtDatabaseScriptsPath} ${databaseSignatures}
```

Some important notes regarding this script:
1. Note that the signature names in the `Dreimt_curation_DB.tsv` file end with `_UP`, `_DN`, or `_sig`. This suffixes must be removed when passing the signature names to this script.
2. The `precalculated-examples` directory of this repository contains a `genesets.gmt` file which contains two genesets used to create the different precalculated examples. This file is updated by this script by taking some genes from all the development database signatures and merging them to create the up and down genesets. This way, it is guaranteed that all signatures in the database has a minimum overlapping with the precalculated examples when running a Jaccard (or Signatures comparison) analysis. If the `genesets.gmt` changes for some reason (e.g. a signature is added or removed), then the script will stop requiring to update the precalculated examples results before proceeding.

# 4. Technical details

## 4.1 `DrugInteractionEffect` encoding
The `DrugInteractionEffect` enumerated in the backend is used in the JPA entities as `EnumType.ORDINAL`, therefore its possible values must be encoded as `BOOST` = `0` and `INHIBIT` = `1` to store them in the database. 

When processing data, this encoding is done by the `process_signatures_geneset_interactions.sh`and `process_signatures_updown_interactions.sh` scripts, using the criteria described below to compute the drug interaction effect on the cell types.

| Interaction type                   	| TAU 	| Boosts 	| Inhibits 	| Prediction summary             	|
|------------------------------------	|-----	|--------	|----------	|--------------------------------	|
| SIGNATURE / SIGNATURE_UP / GENESET 	| > 0 	| A      	| B        	| Drug <span style="color:red">boosts</span> A compared to B    	|
| SIGNATURE / SIGNATURE_UP / GENESET 	| < 0 	| B      	| A        	| Drug <span style="color:green">inhibits</span> A compared to B  	|
| GENESET                            	| > 0 	| A      	| B        	| Drug <span style="color:red">boosts</span> A                   	|
| GENESET                            	| < 0 	| B      	| A        	| Drug <span style="color:green">inhibits</span> A               	|
| SIGNATURE_DOWN                     	| > 0 	| B      	| A        	| Drug <span style="color:red">boosts</span> B compared to A    	|
| SIGNATURE_DOWN                     	| < 0 	| A      	| B        	| Drugs <span style="color:green">inhibits</span> B compared to A 	|

## 4.2 `DrugStatus` encoding
The `DrugStatus` enumerated in the backend is used in the JPA entities as `EnumType.ORDINAL`, therefore its possible values must be encoded as `APPROVED` = `0`, `EXPERIMENTAL` = `1`, and `WITHDRAWN` = `2` to store them in the database. 

When processing data, this encoding is done by the `process_drug.sh` script.

This decision was motivated by the fact that predictions can be ordered using the drug status and using this storage mode allows to use the drug status field as is in the SQL queries (approved are the most important ones and withdrawn the less important ones).
