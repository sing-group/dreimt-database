#!/bin/bash

cat $1 | awk -F'\t' '
    NR>1 {
        gsub(" ", "_", $8);
        printf "INSERT IGNORE INTO drug (commonName, sourceName, sourceDb) VALUES (\"%s\", \"%s\", \"%s\");\n", $9, $10, $11;
        if($15 == "NA") {
            printf "INSERT IGNORE INTO signature (signatureName, sourceDb, experimentalDesign, organism, disease) VALUES (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $3, toupper($8), $6, $7;
        } else {
            printf "INSERT IGNORE INTO signature (signatureName, article_pubmedId, sourceDb, experimentalDesign, organism, disease) VALUES (\"%s\", %s, \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $15, $3, toupper($8), $6, $7;
        }

        # Split cellTypeA column ($4) to insert each value in the corresponding table
        cellTypeACount = split($4, cellTypeA, "|");
        for(i=0; ++i <= cellTypeACount;) {
            printf "INSERT IGNORE INTO signature_cell_type_a (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeA[i];
        }

        # Split cellTypeB column ($4) to insert each value in the corresponding table
        cellTypeBCount = split($5, cellTypeB, "|");
        for(i=0; ++i <= cellTypeBCount;) {
            printf "INSERT IGNORE INTO signature_cell_type_b (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeB[i];
        }

        printf "INSERT INTO drug_signature_interaction (drug_sourceName, drug_sourceDb, signature, tes, pValue, fdr) VALUES (\"%s\", \"%s\", \"%s\", %s, %s, %s);\n", $10, $11, $1, $12, $13, $14;
    }
';
