#!/bin/bash
#fslmaths ACPC -s 25 -thr 1e-6 -bin sphere
# bet $T1MNI MNImask -R -f 0.7
#fslmaths MNImask -kernel sphere 5 -ero -bin MNImask
#fslmaths MNImask -mul sphere -bin mask 

SUBJECTS=$1
export T1FOLDER=$2
export EPIMEANFOLDER=$3
export EPIFOLDER=$4
export T1COREGFOLDER=$5
doit(){
echo "Doing: $1"
eval $1
}

process(){ 
SUBJECT=$1


T1=$T1FOLDER/$SUBJECT/coT1.nii
EPIMEAN=$EPIMEANFOLDER/$SUBJECT/meanadata.nii
EPI=$EPIFOLDER/$SUBJECT/radata.nii

T1reg=$T1
T1coreg=$T1COREGFOLDER/$SUBJECT/coT1.nii

EPIMEANreg=$EPIMEAN
EPIreg=$EPI

T1BET="`tmpnam`.nii.gz"
EPIBET="`tmpnam`.nii.gz"

bet $T1 $T1BET -R -f 0.6
bet $EPIMEAN $EPIBET -R

doit "mri_robust_register --mov $T1BET --dst $T1MNI --lta $T1FOLDER/$SUBJECT/T1toMNIinit.lta --iscale --sat 12 --maxit 10" 
doit "mri_robust_register --mov $T1BET --dst $T1MNI --lta $T1FOLDER/$SUBJECT/T1toMNI.lta --iscale --sat 12 --maskdst $REORIENTMASK --ixform $T1FOLDER/$SUBJECT/T1toMNIinit.lta --maxit 10" 
doit "mri_vol2vol --lta $T1FOLDER/$SUBJECT/T1toMNI.lta --mov $T1 --targ $T1MNI --o $T1reg --no-resample"
doit "mri_vol2vol --lta $T1FOLDER/$SUBJECT/T1toMNI.lta --mov $T1BET --targ $T1MNI --o $T1BET --no-resample"


doit "mri_robust_register --mov $EPIBET --dst $EPIMNI --lta $EPIMEANFOLDER/$SUBJECT/EPItoMNIinit.lta --iscale --sat 12 --maxit 10" 
doit "mri_robust_register --mov $EPIBET --dst $EPIMNI --lta $EPIMEANFOLDER/$SUBJECT/EPItoMNI.lta --iscale --sat 12 --maskdst $REORIENTMASK --ixform $EPIMEANFOLDER/$SUBJECT/EPItoMNIinit.lta --maxit 10"
doit "mri_vol2vol --lta $EPIMEANFOLDER/$SUBJECT/EPItoMNI.lta --mov $EPIMEAN --targ $EPIMNI --o $EPIMEANreg --no-resample"
doit "mri_vol2vol --lta $EPIMEANFOLDER/$SUBJECT/EPItoMNI.lta --mov $EPI --targ $EPIMNI --o $EPIreg --no-resample"
doit "mri_vol2vol --lta $EPIMEANFOLDER/$SUBJECT/EPItoMNI.lta --mov $EPIBET --targ $EPIMNI --o $EPIBET --no-resample"

doit "flirt -in $T1BET -ref $EPIBET -dof 6 -omat $EPIMEANFOLDER/$SUBJECT/T1toEPI.mat" 
doit "mri_vol2vol --mov $T1reg --targ $EPIBET --o $T1coreg --fsl $EPIMEANFOLDER/$SUBJECT/T1toEPI.mat --no-resample"


rm $T1BET $EPIBET 
}


do_loop(){

for SUBJECT in $1; 
do

   PROCESSES=`ps | grep reorient.sh |wc -l`

   while [ $PROCESSES -gt $MAXJOBS ]; do
       #echo "$PROCESSES processes" 
       
       PROCESSES=`ps | grep reorient.sh |wc -l`                    
   done
   process $SUBJECT &
done
}

do_loop "$SUBJECTS"

# wait
while [ `echo $T1COREGFOLDER/* | wc -w` -lt `echo $T1FOLDER/* | wc -w` ]; do  sleep 30; done

