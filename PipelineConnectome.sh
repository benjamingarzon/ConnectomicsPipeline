#!/bin/bash
# requires BrainWavelet, SPM, DPARSFA
# Prepare data in folders $RS_DIR/T1Img and $RS_DIR/FunImg, $SEGS_DIR contains FIRST segmentations, $SUBJECTS_DIR contains freesurfer recons


# data ---------------------------------
DATA_DIR=/home/ALDRECENTRUM/benjamin.garzon/Data/DAD/

FUN_DATA=$DATA_DIR/data/FunImg_TAB
T1_DATA=$DATA_DIR/data/T1Img
export RS_DIR=$DATA_DIR/processed/TAB
export SUBJECTS_DIR=$DATA_DIR/recon
export TIMEPOINTS=660  # GNG: 630, TAB:660, RS:170
export TR=2

SUBJECTS="D02 D03 D04 D05 D07 D08 D11 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22 D23 D24 D25 D26 D29 D30 D31 D33 D34 D35 D36 D37 D38 D39 D40 D42 D43 D46 D47 D48 D49 D50 D52 D55 D56 D58 D60 D61 D62 D63 D64 D65 D66 D67 D70 D72 D80 D82 D83 D84 D85 D86 D90"

# software -----------------------------
SOFT_DIR=/home/ALDRECENTRUM/benjamin.garzon/Software/

export CODES_150=$DATA_DIR/parcellations/shen/Group_seg150_BAindexing_setA.txt
export PARCELLATION=$DATA_DIR/parcellations/shen/fconn_atlas_150_2mm.nii

export EXEC_DIR=$SOFT_DIR/DAD/ConnectivityAnalysis
export BRAINWAV_DIR=$SOFT_DIR/BrainWaveletv1.1/
export LIMIT_RAM=50

export MAXJOBS=10
PARALLEL_WORKERS=15

# do it-----------------------------------
mkdir $RS_DIR
mkdir $RS_DIR/logs 
ln -s $FUN_DATA $RS_DIR/FunImg
ln -s $T1_DATA $RS_DIR/T1Img

mkdir $RS_DIR/Masks

# Run DPARSFA to obtain subject slice time corrected and realigned data
nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage1.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage1.log

# convert realignment parameters
./tsv2csv.py < $RS_DIR/RealignParameter/HeadMotion.tsv > $RS_DIR/RealignParameter/HeadMotion.csv

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_1.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_1.log
nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_1_wcoreg.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_1.log

# wavelet despiking
nohup nice $EXEC_DIR/despike.sh "$SUBJECTS" FunImgAR > $RS_DIR/logs/despike.log

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_2_Wavelet.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_2_Wavelet.log
mv $RS_DIR/FunImgARCFWS $RS_DIR/FunMNIWavelet

nohup nice matlab -nodisplay -nosplash -r "wrapDPARSFA('DPARSFA_cfg/DPARSFA_stage2_MNI_2_no_filter.mat', '$SUBJECTS', '$RS_DIR', $PARALLEL_WORKERS, 0, $TIMEPOINTS); exit" > $RS_DIR/logs/DPARSFA_stage2_MNI_2_no_filter.log
mv $RS_DIR/FunImgARWS $RS_DIR/FunMNI_no_filter

# missing final selection
nohup nice ./ConnectivityPreproc_stage3_MNI.sh "$SUBJECTS" Shen > $RS_DIR/logs/ConnectivityPreproc_stage3.log 

# clean up 
cd $RS_DIR
rm -r FunImgA FunImgARC* FunImgARW*
rm -r T1Img T1ImgBet


