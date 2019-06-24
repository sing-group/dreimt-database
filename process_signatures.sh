#!/bin/bash

cat $1 | awk -F'\t' '
	NR>1 {
		# Accommodate experimental design column (field 11) to DB
		gsub(" ", "_", $11);

		# Fix signature name column (field 1)
		gsub("_UP$|_DN$|_sig$", "", $1);

		# Process only signatures with a signature type (field 12)
		if($12 != "") {
			if($12 == "Gene set") {
				dbSignatureType="GENESET";
			} else {
				dbSignatureType="UPDOWN";
			}

			if($11 == "") {
				dbExperimentalDesign = "UNKNOWN";
			} else {
				dbExperimentalDesign = toupper($11);
			}

			if($14 == "NA") {
				printf "INSERT INTO signature (signatureName, sourceDb, signatureType, experimentalDesign, organism) VALUES (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $2, dbSignatureType, dbExperimentalDesign, $5;
			} else {
				printf "INSERT INTO signature (signatureName, article_pubmedId, sourceDb, signatureType, experimentalDesign, organism) VALUES (\"%s\", %s, \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $14, $2, dbSignatureType, dbExperimentalDesign, $5;
			}

			# Split cellTypeA column ($6) to insert each value in the corresponding table
			cellTypeACount = split($6, cellTypeA, "|");
			for(i=0; ++i <= cellTypeACount;) {
				if(cellTypeA[i] != "") {
					printf "INSERT INTO signature_cell_type_a (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeA[i];
				}
			}

			# Split cellSubTypeA column ($7) to insert each value in the corresponding table
			cellSubTypeACount = split($7, cellSubTypeA, "|");
			for(i=0; ++i <= cellSubTypeACount;) {
				if(cellSubTypeA[i] != "") {
					printf "INSERT INTO signature_cell_subtype_a (signatureName, cellSubType) VALUES (\"%s\", \"%s\");\n", $1, cellSubTypeA[i];
				}
			}

			# Split cellTypeB column ($8) to insert each value in the corresponding table
			cellTypeBCount = split($8, cellTypeB, "|");
			for(i=0; ++i <= cellTypeBCount;) {
				if(cellTypeB[i] != "") {
					printf "INSERT INTO signature_cell_type_b (signatureName, cellType) VALUES (\"%s\", \"%s\");\n", $1, cellTypeB[i];
				}
			}

			# Split cellSubTypeB column ($9) to insert each value in the corresponding table
			cellSubTypeBCount = split($9, cellSubTypeB, "|");
			for(i=0; ++i <= cellSubTypeBCount;) {
				if(cellSubTypeB[i] != "") {
					printf "INSERT INTO signature_cell_subtype_b (signatureName, cellSubType) VALUES (\"%s\", \"%s\");\n", $1, cellSubTypeB[i];
				}
			}

			# Split disease column ($10) to insert each value in the corresponding table
			diseaseCount = split($10, disease, "|");
			for(i=0; ++i <= diseaseCount;) {
				if(disease[i] != "") {
					printf "INSERT INTO signature_disease (signatureName, disease) VALUES (\"%s\", \"%s\");\n", $1, disease[i];
				}
			}
		}
	}
';
