#!/bin/bash

cat $1 | awk -F'\t' '
    NR>1 {
        printf "INSERT INTO article_metadata (pubmedId, title, authors, articleAbstract) VALUES (%s, \"%s\", \"%s\", \"%s\");\n", $1, $2, $3, $4;
    }
';
