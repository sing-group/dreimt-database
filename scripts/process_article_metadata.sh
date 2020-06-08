#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN { 
		printf "INSERT INTO article_metadata (pubmedId, title, authors, articleAbstract) VALUES" 
	}
	NR>2 {
		printf(",");
	}
	NR>1 {
		# Escape single quotes (\x27) so that the MySQL script works properly
		gsub("\x27", "\\\x27",$2)
		gsub("\x27", "\\\x27",$3)
		gsub("\x27", "\\\x27",$4)

		printf "\n  (%s, \x27%s\x27, \x27%s\x27, \x27%s\x27)", $1, $2, $3, $4;
	}
	END { printf ";\n"; }
';
