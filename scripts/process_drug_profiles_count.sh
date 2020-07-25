#!/bin/bash

cat $1 | awk -F'\t' '
	BEGIN {
		printf "\n"
	}
	{
		printf "\nUPDATE drug SET dbProfilesCount = %s WHERE commonName = \"%s\";", $2, $1;
	}
';
