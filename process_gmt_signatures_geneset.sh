 #!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT IGNORE INTO genes (gene, universe) VALUES";
		FIRST = 0;
	}
	{
		if (match($1,"_sig$")){
			for (i=3; i<=NF; i++) {
				if(FIRST>0 && i==3) {
					printf ",";
				} else {
					FIRST = 1;
				}
				printf "\n  (\"%s\", \"F\")", $i;
				if(i<NF) {
					printf ",";
				}
			}
		}
	}
	END { printf ";\n"}
';

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO signature_geneset_genes (gene, signature) VALUES";
		FIRST = 0;
	}
	{
		# Fix signature name column (field 1)
		if (match($1,"_sig$")){
			gsub("_sig$","",$1);

			for (i=3; i<=NF; i++) {
				if(FIRST>0 && i==3) {
					printf ",";
				} else {
					FIRST = 1;
				}
				printf "\n (\"%s\", \"%s\")", $i, $1;
				if(i<NF) {
					printf ",";
				}
			}
		}
	}
	END { printf ";\n\n"}
';
