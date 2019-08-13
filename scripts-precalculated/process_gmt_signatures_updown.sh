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
	END { printf ";\n\n"}
';

cat $1 | grep "_UP" | awk -F'\t' -v UUID=$2 -v TABLE=$3 '
	BEGIN { 
		printf "INSERT INTO %s_up (id, gene) VALUES", TABLE; 
	}
	{
		for (i=3; i<=NF; i++) {
			if(NR>1 && i==3) {
				printf ",";
			}
			printf "\n  (\"%s\", \"%s\")", UUID, $i;

			if(i<NF) {
				printf ",";
			}
		}
	}
	END { printf ";\n\n"}
';

cat $1 | grep "_DN" | awk -F'\t' -v UUID=$2 -v TABLE=$3 '
	BEGIN { 
		printf "INSERT INTO %s_down (id, gene) VALUES", TABLE;
	}
	{
		for (i=3; i<=NF; i++) {
			if(NR>1 && i==3) {
				printf ",";
			}
			printf "\n  (\"%s\", \"%s\")", UUID, $i;

			if(i<NF) {
				printf ",";
			}
		}
	}
	END { printf ";\n\n"}
';
