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
		printf "INSERT INTO signature_geneset_genes (gene, signature) VALUES" 
	}
	{
		# Fix signature name column (field 1)
		if (match($1,"_UP")){
			gsub("_UP$","",$1);
		} else if (match($1,"_DN")){
			gsub("_DN$","",$1);
		} else {
			gsub("_sig$","",$1);
		}
		
		for (i=3; i<=NF; i++) {
			if(NR>1 && i==3) {
				printf ",";
			}
			printf "\n (\"%s\", \"%s\")", $i, $1;
			if(i<NF) {
				printf ",";
			}
		}
	}
	END { printf ";\n\n"}
';
