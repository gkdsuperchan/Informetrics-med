# Informetrics-med

1. Use step01.getsh.sh to generate shells for geting paper's information, and run it in Folder 'shells';
2. Then do these five steps to annotate the information of each manuscript: 
3.   s1.annotpaper.ipynb was used to add IF,IF5year,JCR Rank,etc.;
4.   s2.annotzky.ipynb was used for the corresponding journal of the article annotation for its classification by the Chinese Academy of Sciences (CAS) and early warning information;
5.   s3.annotzhuoyue.ipynb was used for the annotation whether a manuscript is an outstanding action journal;
6.   s4.mergePMIDs.ipynb was used to merge all paper informations；
7.   s5.highcitedAuthors.ipynb was used to merge the highly cited scientists from previous papers;
8. Next, get a matrix data using step02.getmatrix.sh;
9. Finally, use the matrix data for the single cell analysis:
10.  s6.scplot.Scanpy.ipynb was used for the single-cell analysis.
