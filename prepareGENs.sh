#!/bin/bash

# Name of the fragment to be used.
#
# Read params from command line as keywork arguments
# This is done to be compatible with runMiniAOD.sh which
# which requires this keyargs by CRAB

events=1000
#fragment="BSLLBALL_Photos"
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


#for fragment in BSLLBALL_Photos_Plus BSLLBALL_Photos_Minus BSLLBALL_Photos
#for fragment in BuJpsiK_Alberto BuJpsiK_PHSP BuJpsiK_PHSP_2
for fragment in JPsiK_Official JPsiK_Official_Tag JPsiK_mumuPHSP JPsiK_allPHSP
do

	echo $fragment
	echo $fragment
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

	#cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename GS_${fragment}_step0.py --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN --fileout file:GS_${fragment}_step0.root --step GEN --no_exec --mc -n $events --nThreads 10
	cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename ${fragment}_step0.py --eventcontent GENRAW --datatier GEN --fileout file:GEN_${fragment}_step0.root --conditions 102X_upgrade2018_realistic_v11 --step GEN --era Run2_2018 --no_exec --mc -n $events --nThreads 10
	sed -i "20 a from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper \nrandSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)\nrandSvc.populate()"  ${fragment}_step0.py
	#cmsDriver.py Configuration/GenProduction/python/${fragment}.py --python_filename NFGS_${fragment}_step0.py --eventcontent GENRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN --fileout file:NFGS_${fragment}_step0.root --conditions 102X_upgrade2018_realistic_v11 --beamspot Realistic25ns13TeVEarly2018Collision --step GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n $events --nThreads 10

	#cmsRun GS_${fragment}_step0.py
	#cmsRun mc_analyzer_cfg.py out=GS_${fragment} input=GS_${fragment}_step0 
	cd CMSSW_10_2_20_UL/src

done



