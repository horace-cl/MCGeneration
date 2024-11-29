#!/bin/bash

# Name of the fragment to be used.
fragment="BdToK0sMuMu_MuK0sFilter_PHSP"

GEN_REL="CMSSW_13_0_17"
RECO_REL="CMSSW_13_0_14"
MINI_REL="CMSSW_13_0_14"


for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            fragment)           fragment=${VALUE} ;;
            *)   
    esac    


done


echo "fragment = $fragment"
echo " "
echo " "
echo "================ STARTING ====================="
directory=$(dirname -- $(readlink -fn -- "$0"))
echo $directory
a=`ls -la`
IFS='$'
echo -e ${a[0]}
echo "================ STARTING ====================="
echo " "
echo " "




echo "\n\n==================== cmssw environment prepration Gen step ====================\n\n"
source /cvmfs/cms.cern.ch/cmsset_default.sh
#export SCRAM_ARCH=$SCRAM

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

echo "========== ============================== ========== "
echo "==================== FILE SIZE! ==================== "
echo "========== ============================== ========== "
du -h GS_${fragment}_step0.root
echo "========== ============================== ========== "
echo "========== ============================== ========== "





if [ -r $RECO_REL/src ] ; then
    echo release $RECO_REL already exists
else
    scram p CMSSW $RECO_REL
fi
cd $RECO_REL/src
eval `scram runtime -sh`
scram b
cd ../../



echo "==================== PB: CMSRUN starting DigiReco step ===================="
cmsRun -e -j ${fragment}_step1.log DR_${fragment}_step1.py 
echo "========== ============================== ========== "
echo "==================== FILE SIZE! ==================== "
echo "========== ============================== ========== "
du -h DR_${fragment}_step1.root
echo "========== ============================== ========== "
echo "========== ============================== ========== "



echo "================= PB: CMSRUN starting AOD step 2 ===================="
cmsRun -e -j ${fragment}_step2.log AOD_${fragment}_step2.py
echo "========== ============================== ========== "
echo "==================== FILE SIZE! ==================== "
echo "========== ============================== ========== "
du -h AOD_${fragment}_step2.root
echo "========== ============================== ========== "
echo "========== ============================== ========== "



echo "================= PB: CMSRUN starting MINIAOD step 3 ===================="
#cmsRun -e -j ${fragment}_step3.log MINIAOD_${fragment}_step3.py
cmsRun -e -j FrameworkJobReport.xml -p MINIAOD_${fragment}_step3.py
echo "========== ============================== ========== "
echo "==================== FILE SIZE! ==================== "
echo "========== ============================== ========== "
du -h MINIAOD_${fragment}_step3.root
echo "========== ============================== ========== "
echo "========== ============================== ========== "