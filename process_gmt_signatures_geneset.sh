#!/bin/bash

cat $1 | awk -F'\t' '
    {
        for (i=3; i<=NF; i++) {
            printf "INSERT INTO signature_geneset_genes (gene, signature) VALUES (\"%s\", \"%s\");\n", $i, $signatureName;
        }
    }
';
