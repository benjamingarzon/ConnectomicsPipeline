#!/bin/bash
# requires BrainWavelet, SPM, DPARSFA
# Prepare data in folders $RS_DIR/T1Img and $RS_DIR/FunImg
# Revise manual registrations

# data ---------------------------------
DATA_DIR=/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/
TASK=RS
FUN_DATA=$DATA_DIR/data/FunImg_$TASK
T1_DATA=$DATA_DIR/data/T1Img

export RS_DIR=$DATA_DIR/processed/$TASK
export SUBJECTS_DIR=$DATA_DIR/recon
export TIMEPOINTS=170  # GNG: 630, TAB:660, RS:170
export TR=2
export MINSCANS=150

SUBJECTS="D02 D03 D04 D05 D07 D08 D11 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22 D23 D24 D25 D26 D29 D30 D31 D33 D34 D35 D36 D37 D38 D39 D40 D42 D43 D46 D47 D48 D49 D50 D52 D55 D56 D58 D60 D61 D62 D63 D64 D65 D66 D67 D70 D72 D80 D82 D83 D84 D85 D86 D90"

# software -----------------------------
SOFT_DIR=/home/ALDRECENTRUM/benjamin.garzon/Software/

export CODES_50=$DATA_DIR/parcellations/shen/Group_seg50_BAindexing_setA.txt
export CODES_150=$DATA_DIR/parcellations/shen/Group_seg150_BAindexing_setA.txt
export PARCELLATION_50=$DATA_DIR/parcellations/shen/fconn_atlas_50_2mm.nii
export PARCELLATION_150=$DATA_DIR/parcellations/shen/fconn_atlas_150_2mm.nii

export REORIENTMASK=$DATA_DIR/templates/reorientmask.nii.gz
export T1MNI=$DATA_DIR/templates/T1MNI_bet.nii.gz 
export EPIMNI=$DATA_DIR/templates/EPIMNI_bet.nii.gz

export EXEC_DIR=$SOFT_DIR/DAD/ConnectivityAnalysis
export BRAINWAV_DIR=$SOFT_DIR/BrainWaveletv1.1/
export LIMIT_RAM=50

export MAXJOBS=8

PARALLEL_WORKERS=10
WAVELET=0

SCRUB=0.5

# do it-----------------------------------
#rm -r $RS_DIR
mkdir $RS_DIR
mkdir $RS_DIR/logs
ln -s $FUN_DATA $RS_DIR/FunImg
cp -r $T1_DATA $RS_DIR/T1Img
mkdir $RS_DIR/T1ImgCoreg
mkdir $RS_DIR/Masks

# Run DPARSFA to obtain subject slice time corrected and realigned data
nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage1.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage1.log

# convert realignment parameters
$EXEC_DIR/tsv2csv.py < $RS_DIR/RealignParameter/HeadMotion.tsv > $RS_DIR/RealignParameter/HeadMotion.csv

#cp -r $RS_DIR/FunImgAR $RS_DIR/FunImgAR_bu

# perform reorientation
$EXEC_DIR/reorient.sh "$SUBJECTS" $RS_DIR/T1Img $RS_DIR/RealignParameter $RS_DIR/FunImgAR $RS_DIR/T1ImgCoreg > $RS_DIR/logs/reorient.log

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_1.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_1.log

if [ $WAVELET -eq 1 ]; then
SUFFIX=Wav

# wavelet despiking
nohup nice $EXEC_DIR/despike.sh "$SUBJECTS" FunImgAR > $RS_DIR/logs/despike.log

cp -r $RS_DIR/FunImgAR $RS_DIR/FunImgAR_despiked
rm $RS_DIR/FunImgAR/*/*bet* $RS_DIR/FunImgAR/*/*noise* $RS_DIR/FunImgAR/*/*undespiked*

$EXEC_DIR/CheckSPs.sh "$SUBJECTS"  $RS_DIR/FunImgAR 5 $RS_DIR/subjects_included.txt

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_2_Wavelet.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_2_Wavelet.log
mv $RS_DIR/FunImgARCFWS $RS_DIR/FunMNIWavelet
SUBJECTS_INCLUDED=`cat $RS_DIR/Subjects_included.txt`

else
SUFFIX=$SCRUB

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_2.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, $SCRUB, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_2.log
mv $RS_DIR/FunImgARCFWSB $RS_DIR/FunMNI$SCRUB

./CheckLengthAfterScrubbing.sh ${SCRUB} ${MINSCANS} $RS_DIR/FunMNI$SCRUB
SUBJECTS_INCLUDED=`cat $RS_DIR/Subjects_${SCRUB}_${MINSCANS}.txt`

fi

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_2_no_filter.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_2_no_filter.log
mv $RS_DIR/FunImgARWS $RS_DIR/FunMNI_no_filter

nohup nice ./ConnectivityPreproc_stage3_MNI.sh "$SUBJECTS_INCLUDED" $SUFFIX > $RS_DIR/logs/ConnectivityPreproc_stage3.log 


fslmerge -t $RS_DIR/Connectome$SUFFIX/mean_signal $RS_DIR/Connectome$SUFFIX/*/mean_fmri.nii.gz
fslmaths $RS_DIR/Connectome$SUFFIX/mean_signal -Tmin $RS_DIR/Connectome$SUFFIX/min_signal 

cd $RS_DIR/Connectome$SUFFIX/
matlab -nodisplay -nosplash -r "addpath $EXEC_DIR; merge_matrices_shen('`echo $SUBJECTS_INCLUDED`', 'zFC_50.csv', '$CODES_50', 'zFC_all_50_${SUFFIX}_${TASK}.mat'); exit" 
matlab -nodisplay -nosplash -r "addpath $EXEC_DIR; merge_matrices_shen('`echo $SUBJECTS_INCLUDED`', 'zFC_150.csv', '$CODES_150', 'zFC_all_150_${SUFFIX}_${TASK}.mat'); exit" 

# clean up 
cd $RS_DIR
rm -r FunImgA* FunMNI*
rm -r T1Img T1ImgBet


