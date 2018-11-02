#!/bin/bash

cat $1 | awk -F'\t' '
    NR>1 {
        gsub(" ", "_", $9);
        printf "INSERT IGNORE INTO drug (commonName, sourceName, sourceDb) VALUES (\"%s\", \"%s\", \"%s\");\n", $10, $11, $12;
        if($16 == "NA") {
            printf "INSERT IGNORE INTO signature (signatureName, sourceDb, signatureType, experimentalDesign, organism, disease) VALUES (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $3, $4, toupper($9), $7, $8;
        } else {
            printf "INSERT IGNORE INTO signature (signatureName, article_pubmedId, sourceDb, signatureType, experimentalDesign, organism, disease) VALUES (\"%s\", %s, \"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $16, $3, $4, toupper($9), $7, $8;
        }

        # Split cellTypeA column ($5) to insert each value in the corresponding table
        cellTypeACount = split($5, cellTypeA, "|");
        for(i=0; ++i <= cellTypeACount;) {
            printf "INSERT IGNORE INTO signature_cell_type_a (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeA[i];
        }

        # Split cellTypeB column ($6) to insert each value in the corresponding table
        cellTypeBCount = split($6, cellTypeB, "|");
        for(i=0; ++i <= cellTypeBCount;) {
            printf "INSERT IGNORE INTO signature_cell_type_b (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeB[i];
        }

        printf "INSERT INTO drug_signature_interaction (drug_sourceName, drug_sourceDb, signature, tes, pValue, fdr) VALUES (\"%s\", \"%s\", \"%s\", %s, %s, %s);\n", $11, $12, $1, $13, $14, $15;
    }
';
