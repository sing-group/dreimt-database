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
				printf "INSERT INTO signature (signatureName, sourceDb, sourceDbUrl, signatureType, experimentalDesign, organism, localisationA, localisationB, stateA, stateB, cellTypeA, cellSubTypeA, cellTypeB, cellSubTypeB, cellTypeAOntologyId, cellSubTypeAOntologyId, cellTypeBOntologyId, cellSubTypeBOntologyId) VALUES (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $2, $3, dbSignatureType, dbExperimentalDesign, $5, $18, $19, $22, $23, $6, $7, $8, $9, $24, $25, $26, $27;
			} else {
				printf "INSERT INTO signature (signatureName, article_pubmedId, sourceDb, sourceDbUrl, signatureType, experimentalDesign, organism, localisationA, localisationB, stateA, stateB, cellTypeA, cellSubTypeA, cellTypeB, cellSubTypeB, cellTypeAOntologyId, cellSubTypeAOntologyId, cellTypeBOntologyId, cellSubTypeBOntologyId) VALUES (\"%s\", %s, \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\");\n", $1, $14, $2, $3, dbSignatureType, dbExperimentalDesign, $5, $18, $19, $22, $23, $6, $7, $8, $9, $24, $25, $26, $27;
			}

			# Split disease column ($10) to insert each value in the corresponding table
			diseaseCount = split($10, disease, "|");
			for(i=0; ++i <= diseaseCount;) {
				if(disease[i] != "") {
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", disease[i]);
					printf "INSERT INTO signature_disease (signatureName, disease) VALUES (\"%s\", \"%s\");\n", $1, disease[i];
				}
			}

			# Split treatment A ($16) to insert each value in the corresponding table
			treatmentACount = split($16, treatmentA, "|");
			for(i=0; ++i <= treatmentACount;) {
				if(treatmentA[i] != "") {
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", treatmentA[i]);
					printf "INSERT INTO signature_treatment_a (signatureName, treatmentA) VALUES (\"%s\", \"%s\");\n", $1, treatmentA[i];
				}
			}

			# Split treatment B ($17) to insert each value in the corresponding table
			treatmentBCount = split($17, treatmentB, "|");
			for(i=0; ++i <= treatmentBCount;) {
				if(treatmentB[i] != "") {
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", treatmentB[i]);
					printf "INSERT INTO signature_treatment_b (signatureName, treatmentB) VALUES (\"%s\", \"%s\");\n", $1, treatmentB[i];
				}
			}

			# Split disease A ($20) to insert each value in the corresponding table
			diseaseACount = split($20, diseaseA, "|");
			for(i=0; ++i <= diseaseACount;) {
				if(diseaseA[i] != "") {
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", diseaseA[i]);
					printf "INSERT INTO signature_disease_a (signatureName, diseaseA) VALUES (\"%s\", \"%s\");\n", $1, diseaseA[i];
				}
			}

			# Split disease B ($21) to insert each value in the corresponding table
			diseaseBCount = split($21, diseaseB, "|");
			for(i=0; ++i <= diseaseBCount;) {
				if(diseaseB[i] != "") {
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", diseaseB[i]);
					printf "INSERT INTO signature_disease_b (signatureName, diseaseB) VALUES (\"%s\", \"%s\");\n", $1, diseaseB[i];
				}
			}
		}
	}
';
