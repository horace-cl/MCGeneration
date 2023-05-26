#!/bin/bash

# Name of the fragment to be used.
#
# Read params from command line as keywork arguments
# This is done to be compatible with runMiniAOD.sh which
# which requires this keyargs by CRAB

events=2000
fragment="JPsiK_mumuPHSP"
START=0

for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            fragment)           fragment=${VALUE} ;;
            events)             events=${VALUE} ;;     
            *)   
    esac    


done














#####################################################
#################### GENERATION #####################
#####################################################

# Not really sure about `SCRAM_ARCH`
# --- Only know that the ARCHitecture must be ScientificLinux7
# For GEN, in official they use CMSSW_10_2_20(_UL)
# For the first step, we are going to save some additional info
# --- For now that will be defined in a Custom EDAnlyzer
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_20_UL/src ] ; then
  echo release CMSSW_10_2_20_UL already exists
else
  scram p CMSSW CMSSW_10_2_20_UL
fi
cd CMSSW_10_2_20_UL/src
eval `scram runtime -sh`


#Here we are going to place the fragment in an appropiate dir
mkdir -p Configuration/GenProduction/python/
cp ../../Fragments/${fragment}.py Configuration/GenProduction/python/${fragment}.py
#
#The same for the EDAnalyzer and the .xml file
mkdir -p Analyzer/MCanalyzer/plugins/
cp ../../BuildFile.xml Analyzer/MCanalyzer/plugins/BuildFile.xml
cp ../../Analyzer.cc Analyzer/MCanalyzer/plugins/Analyzer.cc

#Compile it!
scram b

#Lets go back to Main directory
# Is it really needed?
cd ../../

#Produce the python cfg  with `cmsDriver` utility
#Look at all flags
cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename GS_${fragment}_step0.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:GS_${fragment}_step0.root --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --step GEN,SIM --geometry DB:Extended --era Run2_2018 --no_exec --mc -n $events

#cmsRun GS_${fragment}_step0.py
#cmsRun mc_analyzer_cfg.py out=GS_${fragment} input=GS_${fragment}_step0 













########################################################################
####################### RECO : GEN-SIM-DIGI-RAW ########################
########################################################################

# https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/BPH-RunIIAutumn18DR-00107
# Up to GEN-SIM-DIGI-RAW

export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_13_patch1/src ] ; then
 echo release CMSSW_10_2_13_patch1 already exists
else
scram p CMSSW CMSSW_10_2_13_patch1
fi
cd CMSSW_10_2_13_patch1/src
eval `scram runtime -sh`

scram b
cd ../../


cmsDriver.py step1 --filein file:GS_${fragment}_step0.root --fileout file:DR_${fragment}_step1.root --pileup_input "dbs:/MinBias_TuneCP5_13TeV-pythia8/RunIIFall18GS-102X_upgrade2018_realistic_v9-v1/GEN-SIM" --mc --eventcontent FEVTDEBUGHLT --pileup "AVE_25_BX_25ns,{'N': 20}" --datatier GEN-SIM-DIGI-RAW --conditions 102X_upgrade2018_realistic_v15 --step DIGI,L1,DIGI2RAW,HLT:@relval2018 --nThreads 1 --geometry DB:Extended --era Run2_2018 --python_filename DR_${fragment}_step1.py  --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1;
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()" DR_${fragment}_step1.py













#####################################################################
######################### RECO : AOD - MINIAOD ######################
#####################################################################

# https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/BPH-RunIIAutumn18RECOBParking-00089
#https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/BPH-RunIIAutumn18MiniAOD-00273

export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_14/src ] ; then
 echo release CMSSW_10_2_14 already exists
else
scram p CMSSW CMSSW_10_2_14
fi
cd CMSSW_10_2_14/src

scram b
cd ../../


cmsDriver.py step2 --filein file:DR_${fragment}_step1.root --fileout file:AOD_${fragment}_step2.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 102X_upgrade2018_realistic_v15 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --nThreads 1 --geometry DB:Extended --era Run2_2018,bParking --python_filename AOD_${fragment}_step2.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1;
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  AOD_${fragment}_step2.py


cmsDriver.py  --python_filename MINIAOD_${fragment}_step3.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:MINIAOD_${fragment}_step3.root --conditions 102X_upgrade2018_realistic_v15 --step PAT --geometry DB:Extended --filein file:AOD_${fragment}_step2.root --era Run2_2018,bParking --runUnscheduled --no_exec --mc -n -1;
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()" MINIAOD_${fragment}_step3.py
