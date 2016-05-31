#!/bin/bash


SUBJECTS="$1"
FOLDER=$2

cd $RS_DIR
cp -r $FOLDER ${FOLDER}_undespiked


correcthd(){
IMAGE=$1
MYTR=$2
fslhd -x $IMAGE > myhdr.txt
sed "s/dt =.*/dt = \'$MYTR\'/" myhdr.txt > myhdr2.txt
fslcreatehd myhdr2.txt $IMAGE
rm myhdr*
}

process(){ 
SUBJECT=$1
cd $RS_DIR/$FOLDER/$SUBJECT

# bet the files
bet radata.nii bet -R -m
fslmaths radata -mas bet_mask -thr 0 radata_bet

#despike 
# wavelet despiking
correcthd radata_bet $TR
matlab -nodisplay -nosplash -r "addpath(genpath('$BRAINWAV_DIR')); WaveletDespike('radata_bet.nii.gz', 'radata', 'SP', 1, 'LimitRAM', $LIMIT_RAM,'threshold', 50); exit"
gunzip radata_wds.nii.gz
mv radata.nii radata_undespiked.nii
gzip radata_undespiked.nii
mv radata_wds.nii radata.nii

#correcthd radata 1
#correcthd radata_undespiked 1
#correcthd radata_noise 1

rm -r /tmp/t*

}

do_loop(){

for SUBJECT in $1; 
do
   echo $SUBJECT
   PROCESSES=`ps | grep ConnectivityPre |wc -l`

   while [ $PROCESSES -gt $MAXJOBS ]; do
       #echo "$PROCESSES processes" 
       
       PROCESSES=`ps | grep ConnectivityPre |wc -l`                    
   done
   process $SUBJECT 
done
}

do_loop "$SUBJECTS"




