#!/bin/bash

# Inputs:
# $1) Input file: tab-delimited, with header line, five columns (1. Target DB Signature Name; 2. Jaccard; 3. pValue; 4. FDR; 5. Source comparison string (for sourceComparisonType) ); ).
# $2) The UUID of the Jaccard result

cat $1 | awk -F'\t' -v UUID=$2 '
	BEGIN {
		printf "INSERT INTO jaccard_result_gene_overlap (fdr, jaccard, pValue, sourceComparisonType, targetComparisonType, jaccardResultId, targetSignature) VALUES";
	}
	NR>2 {
		printf(",");
	}
	NR > 1{
		gsub(/"/, "", $1)
		gsub(/"/, "", $2)
		gsub(/"/, "", $3)
		gsub(/"/, "", $4)
		gsub(/"/, "", $5)
	
		sourceComparisonType=""
		if($5 == "Geneset") {
			sourceComparisonType="GENESET"
		} else if($5 == "Up signature") {
			sourceComparisonType="SIGNATURE_UP"
		} else if($5 == "Down signature") {
			sourceComparisonType="SIGNATURE_DOWN"
		}  

		targetComparisonType=""
		if (match($1,"_UP")){
			targetComparisonType="SIGNATURE_UP"
			gsub("_UP$","",$1);
		} else if (match($1,"_DN")){
			targetComparisonType="SIGNATURE_DOWN"
			gsub("_DN$","",$1);
		} else {
			targetComparisonType="GENESET"
			gsub("_sig$","",$1);
		}

		printf "\n  (%s, %s, %s, \"%s\", \"%s\", \"%s\", \"%s\")", $4, $2, $3, sourceComparisonType, targetComparisonType, UUID, $1;
	}
	END { printf ";\n"; }
';
