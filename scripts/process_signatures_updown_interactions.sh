#!/bin/bash

# Inputs:
# $1) Input file: tab-delimited, without header line, four columns (1: drugId, 2: signature name, 3: tau, 4: UP FDR, 5: DOWN FDR)
# $2) TAU threshold for filtering data

cat $1 | awk -F'\t' -v THRESHOLD=$2 '
	BEGIN {
		printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, upFdr, downFdr, interactionType, cellTypeAEffect, cellTypeBEffect) VALUES";
		PRINT_COMMA = 0;
	}
	(NR % 4000000) == 0 {
		if(NR > 1) {
			printf ";\n\n";
		}
		printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, upFdr, downFdr, interactionType, cellTypeAEffect, cellTypeBEffect) VALUES";
		PRINT_COMMA = 0;
	}
	{
		if($3 >= THRESHOLD || $3 <= -THRESHOLD) {
			if(PRINT_COMMA == 1) {
				printf(",");
			} else {
				PRINT_COMMA = 1;
			}

			# Extract drugId (field 1)
			gsub("sig_","",$1);

			# Fix signature name column (field 2)
			if (match($2,"_UP")){
				gsub("_UP$","",$2);
			} else {
				gsub("_DN$","",$2);
			}

			# IF TAU > 0 THEN BOOSTS (0) CELL TYPE A ELSE INHIBITS (1) CELL TYPE A
			if($3 > 0) {
				cellTypeAEffect = 0;
				cellTypeBEffect = 1;
			} else {
				cellTypeAEffect = 1;
				cellTypeBEffect = 0;
			}

			printf "\n  (%s, \"%s\", %s, %s, %s, \"SIGNATURE\", %s, %s)", $1, $2, $3, $4, $5, cellTypeAEffect, cellTypeBEffect;
		}
	}
	END { printf ";\n"; }
';
