#!/bin/bash
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_20_UL/src ] ; then
  echo release CMSSW_10_2_20_UL already exists
else
  scram p CMSSW CMSSW_10_2_20_UL
fi

cd CMSSW_10_2_20_UL/src
eval `scram runtime -sh`

mkdir -p Analyzer/MCanalyzer/plugins/
cp ../../BuildFile.xml Analyzer/MCanalyzer/plugins/BuildFile.xml
cp ../../Analyzer.cc Analyzer/MCanalyzer/plugins/Analyzer.cc
cp ../../Analyzer_Resonant.cc Analyzer/MCanalyzer/plugins/Analyzer_Resonant.cc
#cp ../../AnalyzerMiniAOD.cc Analyzer/MCanalyzer/plugins/AnalyzerMiniAOD.cc

scram b
