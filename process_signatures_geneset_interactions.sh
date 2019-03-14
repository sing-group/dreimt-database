#!/bin/bash

# Input file: tab-delimited, without header line, four columns (1: drugId, 2: signature name, 3: tau, 4: FDR)

cat $1 | grep -P "_UP\t|_sig\t" | awk -F'\t' '
	BEGIN {
		printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, upFdr, interactionType) VALUES";
		PRINT_COMMA = 0;
	}
	(NR % 4000000) == 0 {
		if(NR > 1) {
			printf ";\n\n";
		}
		printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, upFdr, downFdr, interactionType) VALUES";
		PRINT_COMMA = 0;
	}
	{
		if(PRINT_COMMA == 1) {
			printf(",");
		} else {
			PRINT_COMMA = 1;
		}

		# Extract drugId (field 1)
		gsub("sig_","",$1);

		# Fix signature name column (field 2)
		if (match($2,"_UP")){
			interactionType="SIGNATURE_UP";
			gsub("_UP$","",$2);
		} else {
			interactionType="GENESET";
			gsub("_sig$","",$2);
		}

		printf "\n (%s, \"%s\", %s, %s, \"%s\")", $1, $2, $3, $4, interactionType;
	}
	END { printf ";\n\n"; }
';

cat $1 | grep -P "_DN\t" | awk -F'\t' '
	BEGIN {
	printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, downFdr, interactionType) VALUES"
		PRINT_COMMA = 0;
	}
	(NR % 4000000) == 0 {
		if(NR > 1) {
			printf ";\n\n";
		}
		printf "INSERT INTO drug_signature_interaction (drugId, signature, tau, upFdr, downFdr, interactionType) VALUES";
		PRINT_COMMA = 0;
	}
	{
		if(PRINT_COMMA == 1) {
			printf(",");
		} else {
			PRINT_COMMA = 1;
		}

		# Extract drugId (field 1)
		gsub("sig_","",$1);

		# Fix signature name column (field 2)
		interactionType="SIGNATURE_DOWN";
		gsub("_DN$","",$2);

		printf "\n (%s, \"%s\", %s, %s, \"%s\")", $1, $2, $3, $4, interactionType;
	}
	END { printf ";\n"; }
';
