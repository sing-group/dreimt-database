#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DATA_DIR=$1
BACKEND_URL="${2:-http://dreimt.sing-group.org/dreimt-backend}"

function insertWork {
	resultType=$1
	id=$2
	description=$3
	name=$3
	resultsReference=$4

	creationDateTime=$(date "+%F %H:%M:%S")
	finishingDateTime=$creationDateTime
	schedulingDateTime=$creationDateTime
	startDateTime=$creationDateTime

	status=COMPLETED

	echo -e "INSERT INTO work (resultType, id, description, name, resultReference, creationDateTime, finishingDateTime, schedulingDateTime, startDateTime, status) VALUES (\"$resultType\", \"$id\", \"$description\", \"$name\", \"$resultReference\", \"$creationDateTime\", \"$finishingDateTime\", \"$schedulingDateTime\", \"$startDateTime\", \"$status\");\n"
}

function insertPrecalculatedExample {
	resultType=$1
	id=$2
	resultTypeTable=$3
	tableSubtype=$4

	echo -e "INSERT INTO precalculated_example (resultType, work) VALUES (\"$resultType\", \"$id\");\n"
	echo -e "INSERT INTO $resultTypeTable (work) VALUES (\"$id\");\n"
	echo -e "INSERT INTO ${resultTypeTable}_$tableSubtype (work) VALUES (\"$id\");\n"
}

function insertJaccardResult {
	id=$1
	onlyUniverseGenes=$2
	table=$3

	echo -e "INSERT INTO jaccard_result (id, onlyUniverseGenes) VALUES (\"$id\", \"$onlyUniverseGenes\");\n"
	echo -e "INSERT INTO $table (id) VALUES (\"$id\");\n"
}

function insertCmapResult {
	id=$1
	numPerm=$2
	table=$3

	echo -e "INSERT INTO cmap_result (id, numPerm) VALUES (\"$id\", \"$numPerm\");\n"
	echo -e "INSERT INTO $table (id) VALUES (\"$id\");\n"
}

function processSignatureExample {
	signatureDirectory=$1
	echo -e "\n-- Signature directory: $signatureDirectory"
	
	source $signatureDirectory/metadata
	echo -e "-- Description: $description\n"

	cmapResultsFile="$signatureDirectory/results-cmap.tsv"
	
	if [ -f $cmapResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- CMAP result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/cmap/signature/$uuid"
	
		insertWork "CMAP_UPDOWN" $uuid "$description" $resultReference
		insertPrecalculatedExample "CMAP_UPDOWN" $uuid "precalculated_example_cmap" "updown"
		
		source "$signatureDirectory/results-cmap-params"
		insertCmapResult $uuid $gseaPermutations "cmap_result_updown"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_updown.sh "$signatureDirectory/signature.gmt" $uuid "cmap_result_updown_genes"
		
		$SCRIPTS_DIR/scripts-precalculated/process_cmap_results_updown.sh $cmapResultsFile $uuid
	fi

	jaccardResultsFile="$signatureDirectory/results-jaccard.tsv"
	
	if [ -f $jaccardResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- Jaccard result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/jaccard/$uuid"
	
		insertWork "JACCARD_UPDOWN" $uuid "$description" $resultReference
		insertPrecalculatedExample "JACCARD_UPDOWN" $uuid "precalculated_example_jaccard" "updown"
		
		source "$signatureDirectory/results-jaccard-params"
		insertJaccardResult $uuid $onlyUniverseGenes "jaccard_result_updown"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_updown.sh "$signatureDirectory/signature.gmt" $uuid "jaccard_result_updown_genes"
		
		$SCRIPTS_DIR/scripts-precalculated/process_jaccard_results.sh $jaccardResultsFile $uuid
	fi	
}

if [ -d $DATA_DIR/signatures ]; then
	for signatureDirectory in $(ls -d $DATA_DIR/signatures/*); do
		processSignatureExample $signatureDirectory
	done
fi

function processGenesetExample {
	signatureDirectory=$1
	echo -e "\n-- Signature directory: $signatureDirectory"
	
	source $signatureDirectory/metadata
	echo -e "-- Description: $description\n"

	cmapResultsFile="$signatureDirectory/results-cmap.tsv"
	
	if [ -f $cmapResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- CMAP result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/cmap/geneset/$uuid"
	
		insertWork "CMAP_GENESET" $uuid "$description" $resultReference
		insertPrecalculatedExample "CMAP_GENESET" $uuid "precalculated_example_cmap" "geneset"
		
		source "$signatureDirectory/results-cmap-params"
		insertCmapResult $uuid $gseaPermutations "cmap_result_geneset"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_geneset.sh "$signatureDirectory/geneset.gmt" $uuid "cmap_result_geneset_genes"
		
		$SCRIPTS_DIR/scripts-precalculated/process_cmap_results_geneset.sh $cmapResultsFile $uuid
	fi

	jaccardResultsFile="$signatureDirectory/results-jaccard.tsv"
	
	if [ -f $jaccardResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- Jaccard result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/jaccard/$uuid"
	
		insertWork "JACCARD_GENESET" $uuid "$description" $resultReference
		insertPrecalculatedExample "JACCARD_GENESET" $uuid "precalculated_example_jaccard" "geneset"
		
		source "$signatureDirectory/results-jaccard-params"
		insertJaccardResult $uuid $onlyUniverseGenes "jaccard_result_geneset"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_geneset.sh "$signatureDirectory/geneset.gmt" $uuid "jaccard_result_geneset_genes"

		$SCRIPTS_DIR/scripts-precalculated/process_jaccard_results.sh $jaccardResultsFile $uuid
	fi	
}

if [ -d $DATA_DIR/genesets ]; then
	for genesetDirectory in $(ls -d $DATA_DIR/genesets/*); do
		processGenesetExample $genesetDirectory
	done
fi
