import FWCore.ParameterSet.Config as cms
import os
from pathlib2 import Path
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
                 "Name of the output file or directory")

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
                 
options.register('eosINI', 
                 0,  
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "miniAOD")

options.register('eosEND', 
                 -1,  
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "miniAOD")

options.register('resonanceID',
                0,
                 VarParsing.multiplicity.singleton,
                 VarParsing.varType.int,
                 "resonanceID"
)
#443
                        
options.parseArguments()


debug_ = bool(options.debug)





from glob import glob

# Defining the process
process = cms.Process("Analyzer")

# Adding the process logger, for output when `cmsRun`
process.load("FWCore.MessageService.MessageLogger_cfi")
process.MessageLogger.cerr.FwkReport.reportEvery = options.report
process.maxEvents = cms.untracked.PSet( input = cms.untracked.int32(options.maxE) )



if options.input.endswith('.root'):
	Files = ['file:'+options.input]
elif options.input.endswith('.txt'):
    with open(options.input, 'r') as txt:
        Files = txt.readlines()
else:
	Files = []
	for root,dirs,files in os.walk(options.input):
		good_files = [f for f in files if 'step3' in f and f.endswith('root')]
		if any(good_files):
			#good_files = ['file:'+os.path.join(root,f) for f in good_files]
			Files += ['file:'+os.path.join(root,f) for f in good_files]

if options.eosEND==-1:
	Files=Files[options.eosINI:]
else: 
	Files=Files[options.eosINI:options.eosEND]

process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring(
		   Files
			 #['file:'+options.input+'.root']  
				  ),
    skipEvents=cms.untracked.uint32(options.skip),
		)




if options.out=='automatic' and not options.input.endswith('.root'):
	out_ = os.path.join(options.input, 'GenTuple_'+str(options.eosINI)+'_'+str(options.eosEND)) 
elif not options.out.endswith('root'):
	inpt = options.input[:-1] if options.input.endswith('/') else options.input
	new_dir = os.path.join(options.out, inpt.split('/')[-1])
	Path(new_dir).mkdir(exist_ok=True, parents=True)
	out_ = os.path.join(new_dir, 'GenTuple_'+str(options.eosINI)+'_'+str(options.eosEND))
else:
	out_ = options.out.replace('.root', '')

process.TFileService = cms.Service("TFileService",
         fileName = cms.string(out_+'.root'),                                  
)



Analyzer_Name = 'MCanalyzer' if options.resonanceID==0 else 'MCanalyzerResonant'

if options.miniAOD:
    print(options.miniAOD, '--')
    process.Analyzer = cms.EDAnalyzer(Analyzer_Name,
                                 debug = cms.bool(bool(options.debug)),
                                 resonance_id = cms.int32(options.resonanceID),
								 GenParticles = cms.InputTag("prunedGenParticles")
                                 )
    process.p = cms.Path(process.Analyzer)


else:
    process.Analyzer = cms.EDAnalyzer(Analyzer_Name,
                                 debug = cms.bool(bool(options.debug)),
                                 resonance_id = cms.int32(options.resonanceID),
								 GenParticles = cms.InputTag("genParticles")
                                 )
    process.p = cms.Path(process.Analyzer)




