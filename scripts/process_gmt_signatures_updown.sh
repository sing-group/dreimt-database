#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT IGNORE INTO genes (gene, universe) VALUES" 
	}
	{
		for (i=3; i<=NF; i++) {
			if(NR>1 && i==3) {
				printf ",";
			}
			printf "\n  (\"%s\", \"F\")", $i;
			if(i<NF) {
				printf ",";
			}
		}
	}
	END { printf ";\n"}
';

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO signature_updown_genes (gene, signature, type) VALUES" 
	}
	{
		if (match($1,"_UP")){
			geneType = "UP";
			gsub("_UP$","",$1);
		} else {
			geneType = "DOWN";
			gsub("_DN$","",$1);
		}

		for (i=3; i<=NF; i++) {
			if(NR>1 && i==3) {
				printf ",";
			}
			if (geneType == "UP"){
				printf "\n  (\"%s\", \"%s\", \"UP\")", $i, $1;
			} else {
				printf "\n  (\"%s\", \"%s\", \"DOWN\")", $i, $1;
			}
			if(i<NF) {
				printf ",";
			}
		}
	}
	END { printf ";\n\n"}
';
