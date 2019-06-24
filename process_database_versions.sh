#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO database_versions (version, current) VALUES" 
	}
	NR>2 { 
		printf ","; 
	}
	NR>1 {
		printf "\n  (\"%s\", \"%s\")", $1, $2;
	}
	END { printf ";\n"}
';
