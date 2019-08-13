#!/bin/bash

# Inputs:
# $1) Input file: tab-delimited, with header line, 16 columns (1. Drug ID; 3. UP FDR; 6. DOWN FDR; 9. TAU).
# $2) The UUID of the Cmap result

cat $1 | awk -F'\t' -v UUID=$2 '
	BEGIN {
		printf "INSERT INTO cmap_result_updown_drug_interactions (upFdr, downFdr, tau, cmapResultId, drugId) VALUES";
	}
	NR>2 {
		printf(",");
	}
	NR > 1{
		gsub(/"/, "", $1)
		gsub("sig_","",$1);

		printf "\n  (%s, %s, %s, \"%s\", %s)", $3, $6, $9, UUID, $1;
	}
	END { printf ";\n"; }
';
