#!/bin/bash

# Name of the fragment to be used.
#
# Read params from command line as keywork arguments
# This is done to be compatible with runMiniAOD.sh which
# which requires this keyargs by CRAB

events=100
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
cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename GS_${fragment}_step0.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:GS_${fragment}_step0.root --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --step GEN,SIM --geometry DB:Extended --era Run2_2018,bParking --no_exec --mc -n $events
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper \nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  GS_${fragment}_step0.py
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

cmsDriver.py       --no_exec --mc -n $EVENTS
#cmsDriver.py step1 --filein file:GS_${fragment}_step0.root --fileout file:DR_${fragment}_step1.root --pileup_input "dbs:/MinBias_TuneCP5_13TeV-pythia8/RunIIFall18GS-102X_upgrade2018_realistic_v9-v1/GEN-SIM" --mc --eventcontent FEVTDEBUGHLT --pileup "AVE_25_BX_25ns,{'N': 20}" --datatier GEN-SIM-DIGI-RAW --conditions 102X_upgrade2018_realistic_v15 --step DIGI,L1,DIGI2RAW,HLT:@relval2018 --nThreads 1 --geometry DB:Extended --era Run2_2018,bParking --python_filename DR_${fragment}_step1.py  --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1;
cmsDriver.py step1 --filein file:GS_${fragment}_step0.root --fileout file:DR_${fragment}_step1.root --pileup_input "dbs:/MinBias_TuneCP5_13TeV-pythia8/RunIIFall18GS-102X_upgrade2018_realistic_v9-v1/GEN-SIM" --customise_commands "process.mix.input.nbPileupEvents.probFunctionVariable = cms.vint32(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99) \n process.mix.input.nbPileupEvents.probValue = cms.vdouble(1.286e-05,4.360e-05,1.258e-04,2.721e-04,4.548e-04,7.077e-04,1.074e-03,1.582e-03,2.286e-03,3.264e-03,4.607e-03,6.389e-03,8.650e-03,1.139e-02,1.456e-02,1.809e-02,2.190e-02,2.589e-02,2.987e-02,3.362e-02,3.686e-02,3.938e-02,4.100e-02,4.173e-02,4.178e-02,4.183e-02,4.189e-02,4.194e-02,4.199e-02,4.205e-02,4.210e-02,4.178e-02,4.098e-02,3.960e-02,3.761e-02,3.504e-02,3.193e-02,2.840e-02,2.458e-02,2.066e-02,1.680e-02,1.320e-02,9.997e-03,7.299e-03,5.139e-03,3.496e-03,2.305e-03,1.479e-03,9.280e-04,5.729e-04,3.498e-04,2.120e-04,1.280e-04,7.702e-05,4.618e-05,2.758e-05,1.641e-05,9.741e-06,5.783e-06,3.446e-06,2.066e-06,1.248e-06,7.594e-07,4.643e-07,2.842e-07,1.734e-07,1.051e-07,6.304e-08,3.733e-08,2.179e-08,1.251e-08,7.064e-09,3.920e-09,2.137e-09,1.144e-09,6.020e-10,3.111e-10,1.579e-10,7.880e-11,3.866e-11,1.866e-11,8.864e-12,4.148e-12,1.914e-12,8.721e-13,3.928e-13,1.753e-13,7.757e-14,3.413e-14,1.496e-14,6.545e-15,2.862e-15,1.253e-15,5.493e-16,2.412e-16,1.060e-16,4.658e-17,2.045e-17,8.949e-18,3.899e-18)" --mc --eventcontent FEVTDEBUGHLT --pileup Flat_0_50_25ns --datatier GEN-SIM-DIGI-RAW --conditions 102X_upgrade2018_realistic_v15 --step DIGI,L1,DIGI2RAW,HLT:@relval2018 --nThreads 1 --geometry DB:Extended --era Run2_2018,bParking --python_filename DR_${fragment}_step1.py  --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1;
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
