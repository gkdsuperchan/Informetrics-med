# Informetrics-med

Use step01.getsh.sh to generate shells for geting paper's information, and run it in Folder 'shells';
Then do these five steps to annotate the information of each manuscript:
s1.annotpaper.ipynb was used to add IF,IF5year,JCR Rank,etc.;
s2.annotzky.ipynb was used for the corresponding journal of the article annotation for its classification by the Chinese Academy of Sciences (CAS) and early warning information;
s3.annotzhuoyue.ipynb was used for the annotation whether a manuscript is an outstanding action journal;
s4.mergePMIDs.ipynb was used to merge all paper informations；
s5.highcitedAuthors.ipynb was used to merge the highly cited scientists from previous papers;  
Next, get a matrix data using step02.getmatrix.sh;
Finally, s6.scplot.Scanpy.ipynb was used for the single-cell analysis use the matrix data.
