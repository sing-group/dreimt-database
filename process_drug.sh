#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO drug (id, commonName, sourceDb, sourceName) VALUES" 
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		printf "\n  (%s, \"%s\", \"%s\", \"%s\")", $1, $3, $4, $5;
	}
	END { printf ";\n"}
';
