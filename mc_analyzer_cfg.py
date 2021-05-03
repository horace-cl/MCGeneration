import FWCore.ParameterSet.Config as cms
from FWCore.ParameterSet.VarParsing import VarParsing


#In the line below 'analysis' is an instance of VarParsing object 
options = VarParsing ('analysis')
# Here we have defined our own two VarParsing options 
# add a list of strings for events to process


options.register('maxE',
				  -1,
				  VarParsing.multiplicity.singleton,
				  VarParsing.varType.int,
				  "Events to process")

options.register('report', 
                 100,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "Report every N events")

options.register('skip', 
                 0,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "Skip first N events")

options.register('out', 
                 'GEN_tuple',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "Name of the output file")

options.register('input', 
                 'GS_PHSP_Photos_step0',
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.string,
                 "Name of the input file")

options.register('debug', 
                 0,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "Debug")

options.register('miniAOD', 
                 0,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "miniAOD")
                 
                        
options.parseArguments()


debug_ = bool(options.debug)





from glob import glob

# Defining the process
process = cms.Process("Analyzer")

# Adding the process logger, for output when `cmsRun`
process.load("FWCore.MessageService.MessageLogger_cfi")
process.MessageLogger.cerr.FwkReport.reportEvery = options.report
process.maxEvents = cms.untracked.PSet( input = cms.untracked.int32(options.maxE) )


process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring(
		    ['file:'+options.input+'.root']  
				  ),
    skipEvents=cms.untracked.uint32(options.skip),
		)




process.TFileService = cms.Service("TFileService",
         fileName = cms.string(options.out+'.root'),                                  
)




if options.miniAOD:
    print(options.miniAOD, '--')
    process.Analyzer = cms.EDAnalyzer('MCanalyzerMiniAOD',
                                 debug = cms.bool(True)
                                 )
    process.p = cms.Path(process.Analyzer)


else:
    process.Analyzer = cms.EDAnalyzer('MCanalyzer',
                                 debug = cms.bool(True)
                                 )
    process.p = cms.Path(process.Analyzer)




