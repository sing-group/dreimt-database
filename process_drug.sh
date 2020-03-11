#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO drug (id, commonName, sourceDb, sourceName, status, moa) VALUES"
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		status = toupper($10);
		printf "\n  (%s, \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")", $1, $3, $4, $5, status, $9;
	}
	END { printf ";\n"}
';
