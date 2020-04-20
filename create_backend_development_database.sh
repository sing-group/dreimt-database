#!/bin/bash

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: `basename $0` /path/to/dreimt/database /path/to/dreimt-database/scripts /path/to/dreimt/development/precalculated <signature1|signature2|signature3|signature4>"
  exit 0
fi

DATABASE_DIR=$1
DDB=$2
DEVEL_DB_PRECALCULATED_EXAMPLES=$3
SIGNATURE_NAMES=$4

DEVEL_DB_DIR="$DATABASE_DIR/generated-data/development_database"
TAU_THRESHOLD=75

rm -rf $DEVEL_DB_DIR

mkdir -p $DEVEL_DB_DIR
mkdir -p $DEVEL_DB_DIR/sql $DEVEL_DB_DIR/intermediate

$DDB/process_drug.sh $DATABASE_DIR/Inputs/sig_id_table_LINCS_short.tsv > $DEVEL_DB_DIR/sql/fill_drug.sql

FILTERED_PMIDS=$(cat $DATABASE_DIR/generated-data/intermediate/signatures_step_1.tsv | grep -E "${SIGNATURE_NAMES}" | awk -F'\t' '{print $14}' | paste -sd "|")
echo "Header" > $DEVEL_DB_DIR/intermediate/filtered_pmids.tsv
cat $DATABASE_DIR/generated-data/intermediate/PMIDs.tsv | grep -E ${FILTERED_PMIDS} >> $DEVEL_DB_DIR/intermediate/filtered_pmids.tsv
$DDB/process_article_metadata.sh $DEVEL_DB_DIR/intermediate/filtered_pmids.tsv > $DEVEL_DB_DIR/sql/fill_article_metadata.sql

echo "Header" > $DEVEL_DB_DIR/intermediate/filtered_signatures_step_1.tsv
cat $DATABASE_DIR/generated-data/intermediate/signatures_step_1.tsv | grep -E "${SIGNATURE_NAMES}" >> $DEVEL_DB_DIR/intermediate/filtered_signatures_step_1.tsv
$DDB/process_signatures.sh $DEVEL_DB_DIR/intermediate/filtered_signatures_step_1.tsv > $DEVEL_DB_DIR/sql/fill_signatures.sql

cat $DATABASE_DIR/Inputs/Dreimt_Signatures_clean.gmt | grep -E "${SIGNATURE_NAMES}" > $DEVEL_DB_DIR/intermediate/filtered_Dreimt_Signatures_clean.gmt
$DDB/process_gmt_signatures_updown.sh $DEVEL_DB_DIR/intermediate/filtered_Dreimt_Signatures_clean.gmt > $DEVEL_DB_DIR/sql/fill_signatures_updown_genes.sql

cat $DATABASE_DIR/Inputs/Dreimt_Genesets_clean.gmt | grep -E "${SIGNATURE_NAMES}" > $DEVEL_DB_DIR/intermediate/filtered_Dreimt_Genesets_clean.gmt
$DDB/process_gmt_signatures_geneset.sh $DEVEL_DB_DIR/intermediate/filtered_Dreimt_Genesets_clean.gmt > $DEVEL_DB_DIR/sql/fill_signatures_geneset_genes.sql

$DDB/process_genes_universe.sh $DATABASE_DIR/generated-data/intermediate/D1geneUniverse.tsv > $DEVEL_DB_DIR/sql/fill_genes_universe.sql

cat $DATABASE_DIR/generated-data/intermediate/Dreimt_DB_SIG_Annotated.tsv | grep -E "${SIGNATURE_NAMES}" > $DEVEL_DB_DIR/intermediate/filtered_Dreimt_DB_SIG_Annotated.tsv
$DDB/process_signatures_updown_interactions.sh $DEVEL_DB_DIR/intermediate/filtered_Dreimt_DB_SIG_Annotated.tsv > $DEVEL_DB_DIR/sql/fill_signatures_updown_interactions.sql

cat $DATABASE_DIR/generated-data/intermediate/Dreimt_DB_GS_Annotated.tsv | grep -E "${SIGNATURE_NAMES}" > $DEVEL_DB_DIR/intermediate/filtered_Dreimt_DB_GS_Annotated.tsv
$DDB/process_signatures_geneset_interactions.sh $DEVEL_DB_DIR/intermediate/filtered_Dreimt_DB_GS_Annotated.tsv > $DEVEL_DB_DIR/sql/fill_signatures_geneset_interactions.sql

$DDB/process_dreimt_information.sh ${TAU_THRESHOLD} > $DEVEL_DB_DIR/sql/fill_dreimt_information.sql

cp $DATABASE_DIR/generated-data/sql/fill_database_versions.sql $DEVEL_DB_DIR/sql/fill_database_versions.sql

cp -R $DEVEL_DB_PRECALCULATED_EXAMPLES $DEVEL_DB_DIR/intermediate

function processPrecalculatedResults {
	mv $1/results-jaccard.tsv $1/results-jaccard.tsv.original
	head -1 $1/results-jaccard.tsv.original > $1/results-jaccard.tsv
	cat $1/results-jaccard.tsv.original | grep -E "${SIGNATURE_NAMES}" >> $1/results-jaccard.tsv

	mv $1/results-cmap.tsv $1/results-cmap.tsv.original
	head -n 21 $1/results-cmap.tsv.original > $1/results-cmap.tsv
}

processPrecalculatedResults $DEVEL_DB_DIR/intermediate/Precalculated/genesets/1
processPrecalculatedResults $DEVEL_DB_DIR/intermediate/Precalculated/signatures/1

$DDB/process_precalculated_results.sh $DEVEL_DB_DIR/intermediate/Precalculated "http://localhost:8080/dreimt-backend" > $DEVEL_DB_DIR/sql/fill_precalculated_examples.sql

cat $DEVEL_DB_DIR/sql/fill_drug.sql $DEVEL_DB_DIR/sql/fill_article_metadata.sql $DEVEL_DB_DIR/sql/fill_signatures.sql $DEVEL_DB_DIR/sql/fill_signatures_updown_interactions.sql $DEVEL_DB_DIR/sql/fill_signatures_geneset_interactions.sql $DEVEL_DB_DIR/sql/fill_genes_universe.sql $DEVEL_DB_DIR/sql/fill_signatures_updown_genes.sql $DEVEL_DB_DIR/sql/fill_signatures_geneset_genes.sql $DEVEL_DB_DIR/sql/fill_precalculated_examples.sql $DEVEL_DB_DIR/sql/fill_dreimt_information.sql $DEVEL_DB_DIR/sql/fill_database_versions.sql > $DEVEL_DB_DIR/sql/fill_dreimt_db.sql
