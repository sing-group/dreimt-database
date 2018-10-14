#!/bin/bash

cat $1 | awk -F'\t' '
    {
        if (match($1,"_UP")){
            geneType = "UP";
            signatureName = gsub("_UP","",$1);
        } else {
            geneType = "DOWN";
            signatureName = gsub("_DN","",$1);
        }

        for (i=3; i<=NF; i++) {
            if (geneType == "UP"){
                printf "INSERT INTO signature_gene (gene, signature, type) VALUES (\"%s\", \"%s\", \"UP\");\n", $i, $signatureName;
            } else {
                
                printf "INSERT INTO signature_gene (gene, signature, type) VALUES (\"%s\", \"%s\", \"DOWN\");\n", $i, $signatureName;
            }
        }
    }
';
