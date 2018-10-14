#!/bin/bash

cat $1 | awk -F'\t' '
    NR>1 {
        gsub(" ", "_", $8);
        printf "INSERT IGNORE INTO drug (commonName, sourceName, sourceDb) VALUES (\"%s\", \"%s\", \"%s\");\n", $9, $10, $11;
        printf "INSERT IGNORE INTO signature (signatureName, cellTypeA, cellTypeB, article_pubmedId, sourceDb, experimentalDesign, organism, disease) VALUES (\"%s\", \"%s\", \"%s\", %s, \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $4, $5, $15, $3, toupper($8), $6, $7;
        printf "INSERT INTO drug_signature_interaction (drug_sourceName, drug_sourceDb, signature, tes, pValue, fdr) VALUES (\"%s\", \"%s\", \"%s\", %s, %s, %s);\n", $10, $11, $1, $12, $13, $14;
    }
';
