#!/bin/bash

grep -P '\tNA\t' -v $1 | awk -F'\t' '
	BEGIN {
		printf "\nINSERT INTO drug_target_genes (id, geneName, geneId) VALUES"
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		printf "\n  (%s, \"%s\", \"%s\")", $1, $2, $3;
	}
	END { printf ";\n"}
';
