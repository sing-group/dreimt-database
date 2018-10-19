#!/bin/bash

cat $1 | awk -F'\t' '
    NR>1 {
        # Escape single quotes (\x27) so that the MySQL script works properly
        gsub("\x27", "\\\x27",$2)
        gsub("\x27", "\\\x27",$3)
        gsub("\x27", "\\\x27",$4)

        printf "INSERT INTO article_metadata (pubmedId, title, authors, articleAbstract) VALUES (%s, \x27%s\x27, \x27%s\x27, \x27%s\x27);\n", $1, $2, $3, $4;
    }
';
