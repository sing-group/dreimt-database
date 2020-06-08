#!/bin/bash

# Inputs:
# $1) Input file: tab-delimited, with header line, 13 columns (1. Drug ID; 3. FDR; 6. TAU).
# $2) The UUID of the Cmap result

cat $1 | awk -F'\t' -v UUID=$2 '
	BEGIN {
		printf "INSERT INTO cmap_result_geneset_drug_interactions (fdr, tau, cmapResultId, drugId) VALUES";
	}
	NR>2 {
		printf(",");
	}
	NR > 1{
		gsub(/"/, "", $1)
		gsub("sig_","",$1);

		printf "\n  (%s, %s, \"%s\", %s)", $3, $6, UUID, $1;
	}
	END { printf ";\n"; }
';
