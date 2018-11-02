#!/bin/bash

cat $1 | awk -F'\t' '
    {
        printf "INSERT INTO genes (gene, universe) VALUES (\"%s\", \"T\");\n", $0;
    }
';
