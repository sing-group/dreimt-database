#!/bin/bash

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: `basename $0` /path/to/dreimt/database /path/to/dreimt-database/scripts <signature1|signature2|signature3|signature4> [<num_genes_each_signature>]"
  exit 0
fi

DATABASE_DIR=$1
DDB=$2
DEVEL_DB_PRECALCULATED_EXAMPLES="$DDB/../precalculated-examples"
SIGNATURE_NAMES=$3

DEVEL_DB_DIR="$DATABASE_DIR/generated-data/development_database"
DEVEL_DB_GENES_BY_SIGNATURE=${4:-"15"}
TAU_THRESHOLD=75

rm -rf $DEVEL_DB_DIR

mkdir -p $DEVEL_DB_DIR
mkdir -p $DEVEL_DB_DIR/sql $DEVEL_DB_DIR/intermediate

$DDB/process_drug.sh $DATABASE_DIR/Inputs/sig_id_table_LINCS_short.tsv > $DEVEL_DB_DIR/sql/fill_drug.sql
$DDB/process_drug_target_genes.sh $DATABASE_DIR/Inputs/drug_target_genes.tsv >> $DEVEL_DB_DIR/sql/fill_drug.sql
$DDB/process_drug_profiles_count.sh $DATABASE_DIR/generated-data/intermediate/drug_profiles_count.tsv >> $DEVEL_DB_DIR/sql/fill_drug.sql

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

#
# Update the genests.gmt file used to create the precalculated examples by taking genes from all the development database signatures
#

UP_GENES=$(cat $DATABASE_DIR/Inputs/Dreimt_Genesets_clean.gmt | grep -E $databaseSignatures | grep -P '_UP\t' | awk -v DEVEL_DB_GENES_BY_SIGNATURE=$DEVEL_DB_GENES_BY_SIGNATURE -F '\t' '{for(i = 3; i <= NF && i < DEVEL_DB_GENES_BY_SIGNATURE; i++) { print $i;}}')
DOWN_GENES=$(cat $DATABASE_DIR/Inputs/Dreimt_Genesets_clean.gmt | grep -E $databaseSignatures | grep -P '_DN\t' | awk -v DEVEL_DB_GENES_BY_SIGNATURE=$DEVEL_DB_GENES_BY_SIGNATURE -F '\t' '{for(i = 3; i <= NF && i < DEVEL_DB_GENES_BY_SIGNATURE; i++) { print $i;}}')

GENESET_GENES_1=$(cat $DATABASE_DIR/Inputs/Dreimt_Genesets_clean.gmt | grep -E $databaseSignatures | grep -P '_sig\t' | awk -v DEVEL_DB_GENES_BY_SIGNATURE=$DEVEL_DB_GENES_BY_SIGNATURE -F '\t' '{for(i = 3; i <= NF && i < DEVEL_DB_GENES_BY_SIGNATURE; i = i+2) { print $i;}}')
GENESET_GENES_2=$(cat $DATABASE_DIR/Inputs/Dreimt_Genesets_clean.gmt | grep -E $databaseSignatures | grep -P '_sig\t' | awk -v DEVEL_DB_GENES_BY_SIGNATURE=$DEVEL_DB_GENES_BY_SIGNATURE -F '\t' '{for(i = 4; i <= NF && i < DEVEL_DB_GENES_BY_SIGNATURE; i = i+2) { print $i;}}')

UP_GENES=$(echo -e "$UP_GENES\n$GENESET_GENES_1" | sort -u |  tr '\n' '\t' | sed 's/\t$//g')
DOWN_GENES=$(echo -e "$DOWN_GENES\n$GENESET_GENES_2" | sort -u |  tr '\n' '\t' | sed 's/\t$//g')

if [ -f $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old ]; then
	echo "Found $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old file, it seems the last time you ran this script the geneset file was changed and you may have not rebuild the precalculated examples yet"
	exit 1
fi

if [ -f $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt ]; then
	mv $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old
fi

echo -e "Genes_UP\t\t$UP_GENES" > $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt
echo -e "Genes_DN\t\t$DOWN_GENES" >> $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt

if [ -f $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old ]; then
	DIFF=$(diff $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old)
	if [ "$DIFF" ]; then
		echo "The source GMT genes file was modified, you must build the precalculated examples before continue";
		exit 1
	else
		rm $DEVEL_DB_PRECALCULATED_EXAMPLES/genesets.gmt.old
	fi
fi

rm -rf $DEVEL_DB_DIR/intermediate/precalculated-examples
cp -R $DEVEL_DB_PRECALCULATED_EXAMPLES $DEVEL_DB_DIR/intermediate

function processPrecalculatedResults {
	if [ -f $1/results-jaccard.tsv ]; then 
		mv $1/results-jaccard.tsv $1/results-jaccard.tsv.original
		head -1 $1/results-jaccard.tsv.original > $1/results-jaccard.tsv
		cat $1/results-jaccard.tsv.original | grep -E "${SIGNATURE_NAMES}" >> $1/results-jaccard.tsv
	fi

	if [ -f $1/results-cmap.tsv ]; then 
		mv $1/results-cmap.tsv $1/results-cmap.tsv.original
		head -n 21 $1/results-cmap.tsv.original > $1/results-cmap.tsv
	fi
}

processPrecalculatedResults $DEVEL_DB_DIR/intermediate/precalculated-examples/genesets/1
processPrecalculatedResults $DEVEL_DB_DIR/intermediate/precalculated-examples/genesets/2
processPrecalculatedResults $DEVEL_DB_DIR/intermediate/precalculated-examples/genesets/3
processPrecalculatedResults $DEVEL_DB_DIR/intermediate/precalculated-examples/signatures/1

$DDB/process_precalculated_results.sh $DEVEL_DB_DIR/intermediate/precalculated-examples > $DEVEL_DB_DIR/sql/fill_precalculated_examples.sql

cat $DEVEL_DB_DIR/sql/fill_genes_universe.sql $DEVEL_DB_DIR/sql/fill_drug.sql $DEVEL_DB_DIR/sql/fill_article_metadata.sql $DEVEL_DB_DIR/sql/fill_signatures.sql $DEVEL_DB_DIR/sql/fill_signatures_updown_interactions.sql $DEVEL_DB_DIR/sql/fill_signatures_geneset_interactions.sql $DEVEL_DB_DIR/sql/fill_signatures_updown_genes.sql $DEVEL_DB_DIR/sql/fill_signatures_geneset_genes.sql $DEVEL_DB_DIR/sql/fill_precalculated_examples.sql $DEVEL_DB_DIR/sql/fill_dreimt_information.sql $DEVEL_DB_DIR/sql/fill_database_versions.sql > $DEVEL_DB_DIR/sql/fill_dreimt_db.sql
