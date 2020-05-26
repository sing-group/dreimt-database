#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO drug (id, commonName, sourceDb, sourceName, status, dss) VALUES"
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		status = toupper($10);
		if(status == "APPROVED") {
			status = 0;
		} else if(status == "EXPERIMENTAL") {
			status = 1;
		} else if(status == "WITHDRAWN") {
			status = 2;
		}

		if($12 == "NA") {
			printf "\n  (%s, \"%s\", \"%s\", \"%s\", %s, NULL)", $1, $3, $4, $5, status;
		} else {
			printf "\n  (%s, \"%s\", \"%s\", \"%s\", %s, %s)", $1, $3, $4, $5, status, $12;
		}
	}
	END { printf ";\n\n"}
';

cat $1 | grep -v -i -P '\tUnknown' | awk -F'\t' '
	BEGIN {
		printf "INSERT IGNORE INTO drug_moa (id, moa) VALUES"
	}
	NR>2 {
		printf ",";
	}
	NR>1 {
		moaCount = split($9, moa, ",");
		for(i=0; ++i <= moaCount;) {
			if(moa[i] != "") {
				gsub(/^[[:space:]]+|[[:space:]]+$/,"", moa[i]);
				printf "\n  (%s, \"%s\")", $1, moa[i];
				if(i < moaCount) {
					printf ",";
				}
			}
		}
	}
	END { printf ";\n"}
';

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "\nINSERT IGNORE INTO genes (gene, universe) VALUES" 
		PRINT_COMMA = 0;
	}
	NR>1 {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", $11);
		gsub("^NA$|NA,|,NA", "", $11);
		genesCount = split($11, genes, ",");

		if(NR>1 && genesCount > 0) {
			if(PRINT_COMMA == 1) {
				printf(",");
				PRINT_COMMA = 0;
			}
		}

		for(i=0; ++i <= genesCount;) {
			if(genes[i] != "") {
				gsub(/^[[:space:]]+|[[:space:]]+$/,"", genes[i]);
				printf "\n  (\"%s\", \"F\")", genes[i];
				if(i < genesCount) {
					printf ",";
				} else {
					PRINT_COMMA = 1;
				}
			}
		}
	}
	END { printf ";\n"}
';

cat $1 | awk -F'\t' '
	BEGIN {
		printf "\nINSERT IGNORE INTO drug_target_genes (id, gene) VALUES";
		PRINT_COMMA = 0;
	}
	NR>1 {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", $11);
		gsub("^NA$|NA,|,NA", "", $11);
		genesCount = split($11, genes, ",");

		if(NR>1 && genesCount > 0) {
			if(PRINT_COMMA == 1) {
				printf(",");
				PRINT_COMMA = 0;
			}
		}

		for(i=0; ++i <= genesCount;) {
			if(genes[i] != "") {
				gsub(/^[[:space:]]+|[[:space:]]+$/,"", genes[i]);
				printf "\n  (%s, \"%s\")", $1, genes[i];
				if(i < genesCount) {
					printf ",";
				} else {
					PRINT_COMMA = 1;
				}
			}
		}
	}
	END { printf ";\n"}
';
