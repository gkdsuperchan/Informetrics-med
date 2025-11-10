
#####20240929; Select high-quality and low-quality articles for machine learning
 perl ./perlbin/creatematrix.v10.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/mat/240929/features.tsv ./paper_donload/mat/240929/barcodes.tsv ./paper_donload/mat/240929/matrix.mtx

###Obtain the first affiliation of each manuscript, along with the corresponding city and province, to construct a feature matrix and conduct single-cell analysis；
 perl ./perlbin/creatematrix.v7.3.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/pmid_feature_all169w.241113.txt
