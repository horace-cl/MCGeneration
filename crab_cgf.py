from CRABClient.UserUtilities import config
import datetime
import time

config = config()

st = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d-%H-%M')
date_str = str(datetime.datetime.now()).replace(' ', '_')
date_up_to_minute = '_'.join(date_str.split(':')[0:2])
##This will produce something like: yyyy-mm-dd_hh_mm




fargment = 'PHSP_Photos'
nEvents  = 100
NJOBS    = 10

step0    = "GS_"+fragment+"_step0.py" 
step1    = "DR_"+fragment+"_step1.py"
step2    = "AOD_"+fragment+"_step2.py"
step1    = "MINIAOD_"+fragment+"_step3.py"
skim     = "mc_analyzer_cfg.py"

GEN_file  = "GS_"+fragment+".root"
MINI_file = "MINIAOD_"+fragment+"_step3.root" 


config.General.requestName     = fragment+'-'+date_up_to_minute 
config.General.transferOutputs = True
config.General.transferLogs    = False
config.General.workArea        = 'crab_'+fragment+'-'+date_up_to_minute


config.JobType.allowUndistributedCMSSW = True
config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName   = step0
config.JobType.inputFiles = [ step1, step2, step3, skim] 

config.JobType.disableAutomaticOutputCollection = True
config.JobType.eventsPerLumi = 100
config.JobType.numCores      = 1
#config.JobType.maxMemoryMB  = 3500
config.JobType.scriptExe     = 'runMiniAOD.sh'
#config.JobType.scriptArgs   = [fragment]
config.JobType.outputFiles   = [GEN_file, MINI_file]


config.Data.outputPrimaryDataset = myname
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = nEvents
config.Data.totalUnits = config.Data.unitsPerJob * NJOBS
#config.Data.outLFNDirBase = '/store/user/hcrottel/'
config.Data.publication = False

config.Site.storageSite = 'T3_CH_CERNBOX'
