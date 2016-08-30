#!/bin/sh
cd $3

SCRUB=$1
MINSCANS=$2
rm $RS_DIR/Subjects_${SCRUB}_${MINSCANS}.txt
rm $RS_DIR/Subjects_${SCRUB}_${MINSCANS}_motion.txt

for i in D*; 
do 
       
	l=`fslinfo $i/${i}_4DVolume.nii | grep dim4`
	l=`echo $l | cut -f2 -d' '`
	echo $i: $l
	if [ $l -ge $MINSCANS ]; then
		echo -n "$i " >> $RS_DIR/Subjects_${SCRUB}_${MINSCANS}.txt
	else
		echo -n "$i " >> $RS_DIR/Subjects_${SCRUB}_${MINSCANS}_motion.txt

	fi
done

