#!/bin/bash

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: `basename $0` <database-version> [/path/to/development/precalculated"]
  exit 0
fi

VERSION=$1
WORKING_DIR=${2:-"/home/hlfernandez/Data/Collaborations/CNIO-Dreimt/Database/Development/Precalculated/"}

cd $WORKING_DIR/signatures/1/

rm -f $(pwd)/results-cmap.tsv $(pwd)/results-jaccard.tsv

cp $WORKING_DIR/genesets.gmt $(pwd)/signature.gmt

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/DrugAssociation/Dreimt_UPDN_tau_UserQuery.R $(pwd)/signature.gmt /opt/dreimt/resources/D1_short_t_matrix_12434_4690_LINCS.rds /opt/dreimt/resources/sig_id_table_LINCS_short.tsv 1000 6 /opt/dreimt/resources/DBprecalculated.Coordinated.ES.SIG.rds /opt/dreimt/resources/Normalized_ES_SIG.rds $(pwd)/results-cmap

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/SignatureComparison/Hypergeom_Sig.R $(pwd)/signature.gmt /opt/dreimt/resources/D1geneUniverse.rds /opt/dreimt/resources/Dreimt_Genesets_clean.gmt FALSE $(pwd)/results-jaccard.tsv

cd $WORKING_DIR/genesets/1/

rm -f $(pwd)/results-cmap.tsv $(pwd)/results-jaccard.tsv

cat $WORKING_DIR/genesets.gmt | grep  -P '_UP\t' > $(pwd)/geneset.gmt

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/DrugAssociation/Dreimt_UP_tau_UserQuery.R $(pwd)/geneset.gmt /opt/dreimt/resources/D1_short_t_matrix_12434_4690_LINCS.rds /opt/dreimt/resources/sig_id_table_LINCS_short.tsv 1000 6 /opt/dreimt/resources/DBprecalculated.Coordinated.ES.GS.rds /opt/dreimt/resources/Normalized_ES_GS.rds $(pwd)/results-cmap

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/SignatureComparison/Hypergeom_GS.R $(pwd)/geneset.gmt /opt/dreimt/resources/D1geneUniverse.rds /opt/dreimt/resources/Dreimt_Genesets_clean.gmt FALSE $(pwd)/results-jaccard.tsv

cd $WORKING_DIR/genesets/2/

rm -f $(pwd)/results-cmap.tsv

cat $WORKING_DIR/genesets.gmt | grep  -P '_DN\t' > $(pwd)/geneset.gmt

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/DrugAssociation/Dreimt_UP_tau_UserQuery.R $(pwd)/geneset.gmt /opt/dreimt/resources/D1_short_t_matrix_12434_4690_LINCS.rds /opt/dreimt/resources/sig_id_table_LINCS_short.tsv 1000 6 /opt/dreimt/resources/DBprecalculated.Coordinated.ES.GS.rds /opt/dreimt/resources/Normalized_ES_GS.rds $(pwd)/results-cmap

cd $WORKING_DIR/genesets/3/

rm -f $(pwd)/results-cmap.tsv

cat $WORKING_DIR/genesets.gmt | grep  -P '_UP\t' > $(pwd)/geneset.gmt

docker run --rm -it -v $(pwd):$(pwd) singgroup/r-dreimt-scripts:${VERSION} Rscript /opt/dreimt/dreimt/src/DrugAssociation/Dreimt_UP_tau_UserQuery.R $(pwd)/geneset.gmt /opt/dreimt/resources/D1_short_t_matrix_12434_4690_LINCS.rds /opt/dreimt/resources/sig_id_table_LINCS_short.tsv 1000 6 /opt/dreimt/resources/DBprecalculated.Coordinated.ES.GS.rds /opt/dreimt/resources/Normalized_ES_GS.rds $(pwd)/results-cmap

if [ -f $WORKING_DIR/genesets.gmt.old ]; then
	rm $WORKING_DIR/genesets.gmt.old
fi
