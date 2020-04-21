#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO drug (id, commonName, sourceDb, sourceName, status) VALUES"
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		status = toupper($10);
		printf "\n  (%s, \"%s\", \"%s\", \"%s\", \"%s\")", $1, $3, $4, $5, status;
	}
	END { printf ";\n\n"}
';

cat $1 | awk -F'\t' '
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
				gsub(/^[[:space:]]+|[[:space:]]+$/,"",moa[i]);
				printf "\n  (%s, \"%s\")", $1, moa[i];
				if(i < moaCount) {
					printf ",";
				}
			}
		}
	}
	END { printf ";\n"}
';
