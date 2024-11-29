#!/bin/bash

# Name of the fragment to be used.
#
# Read params from command line as keywork arguments
# This is done to be compatible with runMiniAOD.sh which
# which requires this keyargs by CRAB

events=100
fragment="BdToK0sMuMu_MuK0sFilter_PHSP"




#####################################################
#################### GENERATION #####################
#####################################################

export SCRAM_ARCH=el8_amd64_gcc11

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_17/src ] ; then
  echo release CMSSW_13_0_17 already exists
else
  scram p CMSSW CMSSW_13_0_17
fi
cd CMSSW_13_0_17/src
eval `scram runtime -sh`


#Here we are going to place the fragment in an appropiate dir
mkdir -p Configuration/GenProduction/python/
cp ../../../../Fragments/${fragment}.py Configuration/GenProduction/python/${fragment}.py

#Compile it!
scram b

#Lets go back to Main directory
# Is it really needed?
cd ../../

#Produce the python cfg  with `cmsDriver` utility
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/BPH-Run3Summer23BPixGS-00119
cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename GS_${fragment}_step0.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:GS_${fragment}_step0.root --conditions 130X_mcRun3_2023_realistic_postBPix_v6 --beamspot Realistic25ns13p6TeVEarly2023Collision --step GEN,SIM --geometry DB:Extended --era Run3_2023 --no_exec --mc -n $events
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper \nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  GS_${fragment}_step0.py






# ########################################################################
# ####################### RECO : GEN-SIM-DIGI-AOD ########################
# ########################################################################
export SCRAM_ARCH=el8_amd64_gcc11

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_14/src ] ; then
  echo release CMSSW_13_0_14 already exists
else
  scram p CMSSW CMSSW_13_0_14
fi
cd CMSSW_13_0_14/src
eval `scram runtime -sh`

scram b
cd ../..


# SIM-RAW
# cmsDriver command
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/BPH-Run3Summer23BPixDRPremix-00120
cmsDriver.py  --python_filename DR_${fragment}_step1.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:DR_${fragment}_step1.root --pileup_input "dbs:/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23BPix_130X_mcRun3_2023_realistic_postBPix_v1-v1/PREMIX" --conditions 130X_mcRun3_2023_realistic_postBPix_v6 --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2023v12    --procModifiers premix_stage2 --geometry DB:Extended --filein file:GS_${fragment}_step0.root --datamix PreMix --era Run3_2023 --no_exec --mc -n -1
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()" DR_${fragment}_step1.py

# AOD
# cmsDriver command
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/BPH-Run3Summer23BPixDRPremix-00120
cmsDriver.py  --python_filename AOD_${fragment}_step2.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:AOD_${fragment}_step2.root --conditions 130X_mcRun3_2023_realistic_postBPix_v6 --step RAW2DIGI,L1Reco,RECO,RECOSIM --geometry DB:Extended --filein file:DR_${fragment}_step1.root --era Run3_2023 --no_exec --mc -n -1
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  AOD_${fragment}_step2.py

# MINIAOD
# cmsDriver command
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/BPH-Run3Summer23BPixMiniAODv4-00120
cmsDriver.py  --python_filename MINIAOD_${fragment}_step3.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:MINIAOD_${fragment}_step3.root --conditions 130X_mcRun3_2023_realistic_postBPix_v6 --step PAT --geometry DB:Extended --filein file:AOD_${fragment}_step2.root --era Run3_2023 --no_exec --mc -n -1
sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper\nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  MINIAOD_${fragment}_step3.py














