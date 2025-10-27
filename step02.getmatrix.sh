
###2024.8.15;added high cited authors and all the 800w global and Chinese papers:
 perl ./perlbin/creatematrix.v2.pl ./paper_donload/paper_all_matrix.added.txt ./paper_donload/pmid_feature_all169w.txt

###2024.8.16;added CNS、医学顶刊、文章数、自引率、掠夺期刊等信息；
 perl ./perlbin/creatematrix.v3.pl ./paper_donload/paper_all_matrix.added.txt ./paper_donload/pmid_feature_all169w.0816.txt

###2024.8.18; 添加Nature index排名；
 perl ./perlbin/creatematrix.v4.pl ./paper_donload/paper_all_matrix.added.txt ./paper_donload/pmid_feature_all169w.0818.txt

###2024.8.21; 修正杂志名称（根据annotJournal.v4.xlsx获取相关内容）；增加5年实际IF、OA实际百分比；
 perl ./perlbin/creatematrix.v5.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/pmid_feature_all169w.0821.txt

######2024.9.3; 修正文章的冗余条目，输出单位对文章的贡献的矩阵
 perl ./perlbin/creatematrix.v7.1.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/pmid_feature_all169w.241008.txt

#####20240908; 选取高质量和低质量的文章进行聚类分析；
 perl ./perlbin/creatematrix.v8.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/mat/240908/features.tsv ./paper_donload/mat/240908/barcodes.tsv ./paper_donload/mat/240908/matrix.mtx

#####20240924; 高质量和低质量的10万多篇文章，输出矩阵用于wgcna分析；
 perl ./perlbin/creatematrix.v9.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/pmid_feature_hign-vs-lowquality.240924-2.txt

#####20240929; 选取高质量和低质量的文章进行聚类分析,去掉grant、OAType；修正0927中因为单位名称处理导致高被引字段丢失的情况；
 perl ./perlbin/creatematrix.v10.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/mat/240929/features.tsv ./paper_donload/mat/240929/barcodes.tsv ./paper_donload/mat/240929/matrix.mtx

###获取每篇文章的第一单位，以及对应的城市，省份；
 perl ./perlbin/creatematrix.v7.3.241113.pl ./paper_donload/paper_all_matrix.240821-2.txt ./paper_donload/pmid_feature_all169w.241113.txt
