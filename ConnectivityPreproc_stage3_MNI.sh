#!/bin/bash
# 
# see parcellations/shen/Group_seg150_BAindexing_setA.txt for codes

SUBJECTS=$1
PREFIX=$2
SIGNAL_THR=0.2
NODE_THR=0.5

mkdir $RS_DIR/Connectome$PREFIX/

process(){ 
SUBJECT=$1

mkdir $RS_DIR/Connectome$PREFIX/$SUBJECT/
cd $RS_DIR/Connectome$PREFIX/$SUBJECT/
echo $SUBJECT
FMRI=$RS_DIR/FunMNIWavelet/$SUBJECT/swFiltered_4DVolume.nii
FMRI_NO_FILTER=$RS_DIR/FunMNI_no_filter/$SUBJECT/swradata.nii

echo $FMRI
# extract time courses from structures
mri_segstats --excludeid 0 --seg $PARCELLATION --i $FMRI --avgwf tcourses_150.csv

# threshold at % mean signal 
fslmaths $FMRI_NO_FILTER -Tmean -thr 10 mean_fmri
# remove bias 
fast -t 2 -o fast -B mean_fmri
MEAN=`fslstats fast_restore -k $PARCELLATION -M`
LEVEL=`echo "$MEAN * $SIGNAL_THR" | bc -l`
fslmaths fast_restore -thr $LEVEL -bin signal_mask
mri_segstats --excludeid 0 --seg $PARCELLATION --i signal_mask.nii.gz --avgwf signal_150.csv

# compute connectivities 
matlab -nodisplay -nosplash -r "addpath $EXEC_DIR; calculate_connectivity_matrix('tcourses_150.csv', 'zFC_150.csv', 'signal_150.csv', $NODE_THR); exit" 

}

do_loop(){

for SUBJECT in $1; 
do

   PROCESSES=`ps | grep ConnectivityPre |wc -l`

   while [ $PROCESSES -gt $MAXJOBS ]; do
       #echo "$PROCESSES processes" 
       
       PROCESSES=`ps | grep ConnectivityPre |wc -l`                    
   done
   process $SUBJECT &
done
}

echo $SUBJECTS
#do_loop "$SUBJECTS"

# merge all the matrices
cd $RS_DIR/Connectome$PREFIX/
echo "Subject Nscans" > NSCANS.csv
for SUBJECT in $SUBJECTS;
do
	echo $SUBJECT `cat $SUBJECT/tcourses_150.csv| wc -l` >> NSCANS.csv
done

matlab -nodisplay -nosplash -r "addpath $EXEC_DIR; merge_matrices_shen('`echo $SUBJECTS`', 'zFC_150.csv', '$CODES_150', 'zFC_all_150.mat'); exit" 

