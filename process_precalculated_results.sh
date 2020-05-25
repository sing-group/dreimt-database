#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DATA_DIR=$1
BACKEND_URL="${2:-http://dreimt.sing-group.org/dreimt-backend}"

function insertWork {
	resultType=$1
	id=$2
	name=$3
	description=$4
	resultsReference=$5

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
	reference=$5
	url=$6

	echo -e "INSERT INTO precalculated_example (resultType, work, reference, url) VALUES (\"$resultType\", \"$id\", \"$reference\", \"$url\");\n"
	echo -e "INSERT INTO $resultTypeTable (work) VALUES (\"$id\");\n"
	echo -e "INSERT INTO ${resultTypeTable}_$tableSubtype (work) VALUES (\"$id\");\n"
}

function unsetMetadataVariables {
	unset description
	unset title
	unset reference
	unset url
	unset geneSetType
	unset caseType
	unset referenceType
}

function processSignatureExample {
	signatureDirectory=$1
	echo -e "\n-- Signature directory: $signatureDirectory"

	unsetMetadataVariables
	source $signatureDirectory/metadata
	echo -e "-- Description: $description"

	cmapResultsFile="$signatureDirectory/results-cmap.tsv"
	
	if [ -f $cmapResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- CMAP result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/drug-prioritization/signature/$uuid"
	
		insertWork "CMAP_UPDOWN" $uuid "$title" "$description" $resultReference
		insertPrecalculatedExample "CMAP_UPDOWN" $uuid "precalculated_example_cmap" "updown" "$reference" "$url"
		
		source "$signatureDirectory/results-cmap-params"

		if [ -z "$referenceType" ]; then 
			echo -e "INSERT INTO cmap_result (id, numPerm, caseType) VALUES (\"$uuid\", \"$gseaPermutations\", \"$caseType\");\n"
		else 
			echo -e "INSERT INTO cmap_result (id, numPerm, caseType, referenceType) VALUES (\"$uuid\", \"$gseaPermutations\", \"$caseType\", \"$referenceType\");\n"
		fi

		echo -e "INSERT INTO cmap_result_updown (id) VALUES (\"$uuid\");\n"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_updown.sh "$signatureDirectory/signature.gmt" $uuid "cmap_result_updown_genes"
		
		$SCRIPTS_DIR/scripts-precalculated/process_cmap_results_updown.sh $cmapResultsFile $uuid
	fi

	jaccardResultsFile="$signatureDirectory/results-jaccard.tsv"
	
	if [ -f $jaccardResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "-- Jaccard result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/signatures-comparison/$uuid"
	
		insertWork "JACCARD_UPDOWN" $uuid "$title" "$description" $resultReference
		insertPrecalculatedExample "JACCARD_UPDOWN" $uuid "precalculated_example_jaccard" "updown" "$reference" "$url"
		
		source "$signatureDirectory/results-jaccard-params"
		echo -e "INSERT INTO jaccard_result (id, onlyUniverseGenes) VALUES (\"$uuid\", \"$onlyUniverseGenes\");\n"
		echo -e "INSERT INTO jaccard_result_updown (id) VALUES (\"$uuid\");\n"

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

	unsetMetadataVariables
	source $signatureDirectory/metadata
	echo -e "-- Description: $description"

	cmapResultsFile="$signatureDirectory/results-cmap.tsv"
	
	if [ -f $cmapResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "\n-- CMAP result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/drug-prioritization/geneset/$uuid"
	
		insertWork "CMAP_GENESET" $uuid "$title" "$description" $resultReference
		insertPrecalculatedExample "CMAP_GENESET" $uuid "precalculated_example_cmap" "geneset" "$reference" "$url"
		
		source "$signatureDirectory/results-cmap-params"

		if [ -z "$referenceType" ]; then 
			echo -e "INSERT INTO cmap_result (id, numPerm, caseType) VALUES (\"$uuid\", \"$gseaPermutations\", \"$caseType\");\n"
		else 
			echo -e "INSERT INTO cmap_result (id, numPerm, caseType, referenceType) VALUES (\"$uuid\", \"$gseaPermutations\", \"$caseType\", \"$referenceType\");\n"
		fi

		echo -e "INSERT INTO cmap_result_geneset (id, geneSetType) VALUES (\"$uuid\", \"$geneSetType\");\n"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_geneset.sh "$signatureDirectory/geneset.gmt" $uuid "cmap_result_geneset_genes"
		
		$SCRIPTS_DIR/scripts-precalculated/process_cmap_results_geneset.sh $cmapResultsFile $uuid
	fi

	jaccardResultsFile="$signatureDirectory/results-jaccard.tsv"

	if [ -f $jaccardResultsFile ]; then 
		uuid=$(uuidgen)
		echo -e "\n-- Jaccard result: $uuid\n"
		
		resultReference="$BACKEND_URL/rest/api/results/signatures-comparison/$uuid"
	
		insertWork "JACCARD_GENESET" $uuid "$title" "$description" $resultReference
		insertPrecalculatedExample "JACCARD_GENESET" $uuid "precalculated_example_jaccard" "geneset" "$reference" "$url"
		
		source "$signatureDirectory/results-jaccard-params"
		echo -e "INSERT INTO jaccard_result (id, onlyUniverseGenes) VALUES (\"$uuid\", \"$onlyUniverseGenes\");\n"
		echo -e "INSERT INTO jaccard_result_geneset (id, geneSetType) VALUES (\"$uuid\", \"$geneSetType\");\n"

		$SCRIPTS_DIR/scripts-precalculated/process_gmt_signatures_geneset.sh "$signatureDirectory/geneset.gmt" $uuid "jaccard_result_geneset_genes"

		$SCRIPTS_DIR/scripts-precalculated/process_jaccard_results.sh $jaccardResultsFile $uuid
	fi	
}

if [ -d $DATA_DIR/genesets ]; then
	for genesetDirectory in $(ls -d $DATA_DIR/genesets/*); do
		processGenesetExample $genesetDirectory
	done
fi
