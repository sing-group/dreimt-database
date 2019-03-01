#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO genes (gene, universe) VALUES" 
	}
	NR>1 { 
		printf ","; 
	}
	{
		printf "\n  (\"%s\", \"T\")", $0;
	}
	END { printf ";\n"}
';
