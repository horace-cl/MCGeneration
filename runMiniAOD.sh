#!/bin/bash

# Name of the fragment to be used.
#
# If number of arguments passed ($#) is equal to zero (-eq 0) 
if [[ $# -eq 0 ]] ; then
	  job=0
    fragment="PHSP_Photos"
    START=0
elif [[ $# -eq 1 ]] ; then
    job=$1
		fragment="PHSP_Photos"
    START=0
elif [[ $# -eq 2 ]] ; then
    job=$1
	  fragment=$2
    START=0
elif [[ $# -eq 3 ]]; then
    job=$1
		fragment=$2
		START=$3
fi
events=50

SCRAM="slc7_amd64_gcc700"
#RELEASE FOR EVERY STEP
#NOTE! AOD STEP REQUIRES SAME RELEASE W.R.T MINIAOD
#AT LEAST FOR THIS MC PRODUCTION
GEN_REL="CMSSW_10_2_20_UL"
RECO_REL="CMSSW_10_2_13_patch1"
MINI_REL="CMSSW_10_2_14"
NANO_REL="CMSSW_10_2_22"


echo "\n\n================ STARTING ====================="
pwd
ls
echo "n================ STARTING =====================\n\n"










if [ $START -le 0 ];
then
	echo "\n\n==================== cmssw environment prepration Gen step ====================\n\n"
	source /cvmfs/cms.cern.ch/cmsset_default.sh
	export SCRAM_ARCH=$SCRAM

	if [ -r $GEN_REL/src ] ; then
	  echo release $GEN_REL already exists
	else
	  scram p CMSSW $GEN_REL
	fi
	cd $GEN_REL/src
	eval `scram runtime -sh`
    cd ../..
    
	echo "==================== PB: CMSRUN starting Gen step ===================="
	  cmsRun -j ${fragment}_step0.log  -p PSet.py
    #cmsRun -j ${fragment}_step0.log -p GS_${fragment}_step0.py
    cmsRun mc_analyzer_cfg.py out=GS_${fragment} input=GS_${fragment}_step0 
fi













if [ $START -le 1 ];
then
	echo "\n\n==================== cmssw environment prepration Reco step ====================\n\n"

	if [ -r $RECO_REL/src ] ; then
	  echo release $RECO_REL already exists
	else
	  scram p CMSSW $RECO_REL
	fi
	cd $RECO_REL/src
	eval `scram runtime -sh`
	scram b
	cd ../../

	echo "==================== PB: CMSRUN starting Reco step ===================="
	cmsRun -e -j ${fragment}_step1.log DR_${fragment}_step1.py 
	#cleaning
	#rm -rfv step0-GS-${CHANNEL_DECAY}.root
fi













if [ $START -le 2 ];
then
	echo "\n\n==================== cmssw environment prepration AOD-MiniAOD format ====================\n\n"
	if [ -r $MINI_REL/src ] ; then
	  echo release $MINI_REL already exists
	else
	  scram p $MINI_REL
	fi

	cd $MINI_REL/src
	eval `scram runtime -sh`
	#scram b distclean && scram b vclean && scram b clean
	scram b
	cd ../../


	echo "================= PB: CMSRUN starting Reco step 2 ===================="
	cmsRun -e -j ${fragment}_step2.log AOD_${fragment}_step2.py
fi

if [ $START -le 3 ];
then
	echo "================= PB: CMSRUN starting step 3 ===================="
	cmsRun -e -j FrameworkJobReport.xml -p MINIAOD_${fragment}_step3.py
	#cmsRun -e -j ${fragment}_step3.log  MINIAOD_${fragment}_step3.py
	#cleaning
	#rm -rfv step2-DR-${CHANNEL_DECAY}.root
fi

