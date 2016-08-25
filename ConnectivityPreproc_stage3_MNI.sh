#!/bin/bash
# 
# see parcellations/shen/Group_seg150_BAindexing_setA.txt for codes

SUBJECTS=$1
SUFFIX=$2
SIGNAL_THR=0.2
NODE_THR=0.5

mkdir $RS_DIR/Connectome$SUFFIX/

process(){ 
SUBJECT=$1

mkdir $RS_DIR/Connectome$SUFFIX/$SUBJECT/
cd $RS_DIR/Connectome$SUFFIX/$SUBJECT/
echo $SUBJECT
FMRI=$RS_DIR/FunMNI$SUFFIX/$SUBJECT/*Volume.nii
FMRI_NO_FILTER=$RS_DIR/FunMNI_no_filter/$SUBJECT/swradata.nii

echo $FMRI
# extract time courses from structures
mri_segstats --excludeid 0 --seg $PARCELLATION_50 --i $FMRI --avgwf tcourses_50.csv
mri_segstats --excludeid 0 --seg $PARCELLATION_150 --i $FMRI --avgwf tcourses_150.csv

# threshold at % mean signal 
fslmaths $FMRI_NO_FILTER -Tmean -thr 10 mean_fmri
# remove bias 
fast -t 2 -o fast -B mean_fmri
MEAN=`fslstats fast_restore -k $PARCELLATION_150 -M`

LEVEL=`echo "$MEAN * $SIGNAL_THR" | bc -l`
fslmaths fast_restore -thr $LEVEL -bin signal_mask
mri_segstats --excludeid 0 --seg $PARCELLATION_50 --i signal_mask.nii.gz --avgwf signal_50.csv
mri_segstats --excludeid 0 --seg $PARCELLATION_150 --i signal_mask.nii.gz --avgwf signal_150.csv

# compute connectivities 
matlab -nodisplay -nosplash -r "addpath $EXEC_DIR; calculate_connectivity_matrix('tcourses_50.csv', 'zFC_50.csv', 'signal_50.csv', $NODE_THR); exit" 
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
do_loop "$SUBJECTS"

# wait
while [ `echo $RS_DIR/Connectome$SUFFIX/*/zFC_150.csv | wc -w` -lt `echo $SUBJECTS | wc -w` ]; do  sleep 30; done

# merge all the matrices
cd $RS_DIR/Connectome$SUFFIX/
echo "Subject Nscans" > NSCANS.csv
for SUBJECT in $SUBJECTS;
do
	echo $SUBJECT `cat $SUBJECT/tcourses_150.csv| wc -l` >> NSCANS.csv
done


