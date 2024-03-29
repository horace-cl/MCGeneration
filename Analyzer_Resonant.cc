// -*- C++ -*-
//
// Package:    Analyze/MCanalyzerResonant
// Class:      MCanalyzerResonant
//
/**\class MCanalyzerResonant MCanalyzerResonant.cc Analyze/MCanalyzerResonant/plugins/MCanalyzerResonant.cc
 Description: [one line class summary]
 Implementation:
     [Notes on implementation]
*/
//
// Original Author:  Horacio Crotte Ledesma
//         Created:  Wed, 02 Sep 2020 19:00:43 GMT
//
//


// system include files
#include <memory>

// user include files
#include "FWCore/Framework/interface/Frameworkfwd.h"
#include "FWCore/Framework/interface/EDAnalyzer.h"

#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/MakerMacros.h"

#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/Utilities/interface/InputTag.h"
#include "DataFormats/TrackReco/interface/Track.h"
#include "DataFormats/TrackReco/interface/TrackFwd.h"

#include "DataFormats/PatCandidates/interface/GenericParticle.h"
#include "DataFormats/PatCandidates/interface/PackedGenParticle.h"


#include "SimDataFormats/GeneratorProducts/interface/HepMCProduct.h"
#include "SimDataFormats/GeneratorProducts/interface/GenEventInfoProduct.h"
#include "SimDataFormats/GeneratorProducts/interface/GenRunInfoProduct.h"

//WE NEED THESE ONES FOR MAKING THE NTUPLES
#include "FWCore/ServiceRegistry/interface/Service.h"
#include "CommonTools/UtilAlgos/interface/TFileService.h"
#include "TFile.h"
#include "TTree.h"
#include "TLorentzVector.h"
#include "TVector3.h"
#include <utility>
#include <string>
#include "Math/GenVector/Boost.h"
#include "TVector3.h"
#include "TMatrixD.h"
#include <Math/VectorUtil.h>
#include "DataFormats/Math/interface/LorentzVector.h"
#include "CommonTools/CandUtils/interface/Booster.h"
#include <vector>
//
// class declaration
//

// If the analyzer does not use TFileService, please remove
// the template argument to the base class so the class inherits
// from  edm::one::EDAnalyzer<>
// This will improve performance in multithreaded jobs.
//
// FROM JHOVANNYS CODE
#include "DataFormats/HepMCCandidate/interface/GenParticle.h"
#include "DataFormats/PatCandidates/interface/GenericParticle.h"



//Is this really needed??
using reco::TrackCollection;







// Class definition
class MCanalyzerResonant : public edm::EDAnalyzer{

   
    public:
      explicit MCanalyzerResonant(const edm::ParameterSet&);
      ~MCanalyzerResonant();

      static void fillDescriptions(edm::ConfigurationDescriptions& descriptions);


    
   private:
      
      virtual void beginJob() override;
      virtual void analyze(const edm::Event&, const edm::EventSetup&) override;
      virtual void endJob() override;

      // ----------member data ---------------------------
      edm::EDGetTokenT<TrackCollection> tracksToken_;  //used to select what tracks to read from configuration file
      edm::EDGetTokenT<edm::HepMCProduct> hepmcproduct_;
      edm::EDGetTokenT<reco::GenParticleCollection> genCands_;
      
      // 4 moment vector ?instantiation? of all "interesting" particles
      TLorentzVector B_p4, K_p4,cc_p4, Muon1_p4,Muon2_p4, Others_p4, OthersRes_p4;
      TLorentzVector B_p4CM,K_p4CM,cc_p4CM, Muon1_p4CM,Muon2_p4CM, Others_p4CM, OthersRes_p4CM;
      // Vertex of the B meson, obtained by .v[x-z]
      TVector3       gen_b_vtx;
      TTree*         tree_;
      // Vector of Ints, for the pdgID of the dauhters
      std::vector<std::vector<int>>    daughter_id, daughter_ids, ancestors;
      // Some other numbers.... do they need to be here?
      int number_daughters, bplus;
      float costhetaL, costhetaKL, costhetaLJ, costhetaKLJ;
			int run, 	luminosityBlock, 	event;
      int resonance_id;
      bool debug=true;
};


//
//genParticles_(consumes<rec::GenParticleCollection>(iConfig.getParameter < edm::InputTag > ("GenParticles"))), constants, enums and typedefs
//

//
// static data member definitions
//

//, 
// constructors and destructor
//
MCanalyzerResonant::MCanalyzerResonant(const edm::ParameterSet& iConfig)
 : genCands_(consumes<reco::GenParticleCollection>(iConfig.getParameter < edm::InputTag > ("GenParticles"))),
 	 number_daughters(0),
   bplus(0),
   costhetaL(-2.0),
   costhetaKL(-2.0),
   costhetaLJ(-2.0),
   costhetaKLJ(-2.0),
	 run(0),
	 luminosityBlock(0),
	 event(0),
   resonance_id(iConfig.getParameter<int>("resonance_id")),
   debug(iConfig.getParameter<bool>("debug"))
{
  std::cout << "INITIALIZER?" << std::endl;
  //genParticles_ = consumes<std::vector<reco::GenParticle>>(edm::InputTag("genParticles"));
	//genParticles_ = consumes<std::vector<pat::PackedGenParticle>>(edm::InputTag("genParticles"));
  hepmcproduct_ = consumes<edm::HepMCProduct>(edm::InputTag("generatorSmeared"));
}


MCanalyzerResonant::~MCanalyzerResonant()
{

   // do anything here that needs to be done at desctruction time
   // (e.g. close files, deallocate resources etc.)

}



//
// member functions
//

// ------------ method called for each event  ------------
void
MCanalyzerResonant::analyze(const edm::Event& iEvent, const edm::EventSetup& iSetup)
{
	
	run = iEvent.id().run();
	luminosityBlock = iEvent.id().luminosityBlock();
	event = iEvent.id().event();
  //bool debug = false;
	if (debug) std::cout << "RUN    : " << run << std::endl;
	if (debug) std::cout << "EVENT  : " << event << std::endl;
	if (debug) std::cout << "LUMI   : " << luminosityBlock<< std::endl;

	//if (debug) std::cout << "LUMI : " << iEvent.getLuminosityBlock().id() << std::endl;


  // Here we are initializing to zero the 4 moments of each particle
  B_p4.SetPxPyPzE(0.,0.,0.,0.);
  K_p4.SetPxPyPzE(0.,0.,0.,0.);
  cc_p4.SetPxPyPzE(0.,0.,0.,0.);

  Muon1_p4.SetPxPyPzE(0.,0.,0.,0.);
  Muon2_p4.SetPxPyPzE(0.,0.,0.,0.);
  Others_p4.SetPxPyPzE(0.,0.,0.,0.);
  OthersRes_p4.SetPxPyPzE(0.,0.,0.,0.);

  B_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  K_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  cc_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  
  Muon1_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  Muon2_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  Others_p4CM.SetPxPyPzE(0.,0.,0.,0.);
  OthersRes_p4CM.SetPxPyPzE(0.,0.,0.,0.);

  costhetaKLJ = -2;
 

  edm::Handle<reco::GenParticleCollection> genParticles;
	iEvent.getByToken(genCands_, genParticles);
	/*if (miniAOD){
		iEvent.getByLabel("prunedGenParticles", genParticles);
	}
	else{
		iEvent.getByLabel("genParticles", genParticles);
	}
	*/


    
  // First we have to check if the genParticles collection is valid
  if ( genParticles.isValid() ) {
      
    if (debug) std::cout << "GenParticles Size = " << genParticles->size() << "\n\n" << std::endl;
    int bplus_ = 0;
    std::vector<int> idsJ;
    std::vector<int> mothers;
    
      
    // First for loop
    // Iterating over the genParticles
    for (size_t i=0; i<genParticles->size(); i++) {
      
        
      int kaon_D = 0;
      int muon_D = 0;
      
      //Which one is correct?
      //First we must extract the i-eth particle
      // It does not make sense to get the Daughter 
      // --- of the particle if we have not identified it
      const reco::GenParticle & p = (*genParticles)[i];  
      //const reco::Candidate *dau = &(*genParticles)[i]; DELETEME
      
      // Basic interesting info of the particle
      int id = p.pdgId();
      int st = p.status();   
      int charge = p.charge();
			unsigned int nDaug = p.numberOfDaughters(); 
      unsigned int nMom  = p.numberOfMothers(); 
      //const reco::Candidate * mom = p.mother();
      
        
        
      // INFORMATION PRINTS
      if ( (abs(id)==521) ){
          if (debug) std::cout << "Particle ID         : " << id    << std::endl;
					if (debug) std::cout << "Particle Charge     : " << charge<< std::endl;
          if (debug) std::cout << "Particle Status     : " << st    << std::endl;
          if (debug) std::cout << "Number of Daughters : " << nDaug << std::endl;
          if (debug) std::cout << "Number of Mother    : " << nMom  << std::endl;
          for (size_t indxMom=0; indxMom<nMom; indxMom++) {
              const reco::Candidate *mom_ = p.mother(indxMom);
              // Save the pdgId of the mothers in a vector  
              mothers.push_back(mom_->pdgId());
              if (debug) std::cout << indxMom <<"   Mother ID       : " << mom_->pdgId()  << std::endl;
              if (debug) std::cout << indxMom <<"   Mother Status   : " << mom_->status() << std::endl;
          }
          if (debug) std::cout << "\n";
      }/*
      else{
          if (debug) std::cout << "     Particle ID     : " << id    << std::endl;
          if (debug) std::cout << "     Particle Status : " << st    << std::endl;
          if (debug) std::cout << "     Number Daughter : " << nDaug << std::endl;
          if (debug) std::cout << "     Number Mother   : " << nMom  << std::endl;
          if (nMom>0){
              if (debug) std::cout << "     Mother ID       : " << mom->pdgId()  << std::endl;
              if (debug) std::cout << "     Mother Status   : " << mom->status()  << "\n" << std::endl;
          }
      }
      */
      // INFORMATION PRINTS
  
        
        
        
        
    
      // ********************************  
      // ******* LOOKING FOR B^+- *******
      // ********************************
      //  
      //Status Flag == 2: (TWIKI)
      // - decayed or fragmented entry 
      //   (i.e. decayed particle or parton produced in shower.)         
      if ( (abs(id) == 521) && (st == 2) ) {
          
            // We have to verify that the B meson has the correct decay
            // That is, it has a kaon and jpsi or psi2s
            bool correctDecay=false, kaon_=false, resonance_=false, muonm_=false,  muonp_=false;
            for (size_t k=0; k<nDaug; k++) {
              const reco::Candidate *daughter_ = p.daughter(k);

              if (debug) std::cout << "     Daughter: Particle ID     : " << daughter_->pdgId()    << std::endl;
              if (debug) std::cout << "     Daughter: Particle Status : " << daughter_->status()    << std::endl;
              if (debug) std::cout << "\n";

              if (abs(daughter_->pdgId())==321) kaon_ = true;
              if (daughter_->pdgId()==-13)     muonm_ = true;
              if (daughter_->pdgId()==+13)     muonp_ = true;
              if (resonance_id==-1) resonance_ = true;

              if (abs(daughter_->pdgId())==resonance_id && resonance_id>-1) {
                resonance_ = true;
                unsigned int nGrandDaug =  daughter_->numberOfDaughters(); 
                for (size_t j=0; j<nGrandDaug; j++){
                  const reco::Candidate *grandaughter_ = daughter_->daughter(j);
                  if (grandaughter_->pdgId()==-13)    muonm_ = true;
                  if (grandaughter_->pdgId()==13)     muonp_ = true;
                }
              }
             
            }
            correctDecay = kaon_ & resonance_ & muonm_ & muonp_;
            //if (debug) std::cout << "+Correct Decay : " << correctDecay << "\n" <<std::endl;

          
            if (correctDecay){
                B_p4.SetPtEtaPhiM(p.pt(),p.eta(),p.phi(),p.mass());
                gen_b_vtx.SetXYZ(p.vx(),p.vy(),p.vz());
                number_daughters = nDaug;
                ancestors.push_back(mothers);
            }
            else{
                mothers.clear();
                if (debug) std::cout << "-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n";
                if (debug) std::cout << " - kaon       " << kaon_      << std::endl;
                if (debug) std::cout << " - resonance  " << resonance_ << std::endl;
                if (debug) std::cout << " - muon+      " << muonp_     << std::endl;
                if (debug) std::cout << " - muon-      " << muonm_     << std::endl;
                if (debug) std::cout << "-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n\n\n";
                
                continue;
            }
          
          
            // Consider events with |pdgID| == 521
            // Status code is a little bit confusing:
            // - TIWKI: 
            //   https://twiki.cern.ch/twiki/bin/view/CMSPublic/WorkBookGenParticleCandidate
            // - PYTHIA8:
            //   http://home.thep.lu.se/~torbjorn/pythia81html/ParticleProperties.html
          
            // How many B mesons are in this event?
            bplus_++;
          
            // Save the 4 momentum of the particle
            // save the PV of the particle?
            // What about its mother?
          
            // Go and take a look at its descendents          
            for (size_t k=0; k<nDaug; k++) {
                
              const reco::Candidate *daughter = p.daughter(k);
              //const reco::Candidate *gdau = dau->daughter(k);
                

              if (debug) std::cout << "- Daughter PdgID     : " << daughter->pdgId() << std::endl;
              if (debug) std::cout << "- Daughter Index     : " << k << std::endl;
              if (debug) std::cout << "- Daughter Status    : " << daughter->status() << std::endl;
              if (debug) std::cout << "- Daughter Daughters : " << daughter->numberOfDaughters() << std::endl;
              if (debug) std::cout << "- Daughter Mothers   : " << daughter->numberOfMothers() << std::endl;  
              if (debug) std::cout << "- Charge of Daughter : " << daughter->charge() << std::endl;
              // We dont save anything if the B meson does not have the 3 final state particles
              // that we need  (K^+, mu^+, mu^-) 
              if (!correctDecay) {
                  if (debug) std::cout << "-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n";
                  continue;
              }
              else{
                  if (debug) std::cout <<"\n";
              }
                
              // Save the pdgId of the daughters in a vector  
              idsJ.push_back(daughter->pdgId());
                
              // We want to save the B^+ -> K^+ mu^+ mu^- Decay (Charge Conjugate implied)
              // If there are more particles in the decay (e.g. Final State Radiation)
              //  Save them in a single Lorentz 4-momentum object
              //  Also save the IDs corresponding to each of them
              //  Maybe their anscestors?  
                
              // Check if daughter is a Kaon
              // and check that they are final state particles: Status == 1
              // -- Twiki:
              //  particle not decayed or fragmented, represents the final state as given by the generator
              if ( (abs(daughter->pdgId())==321)  && (daughter->status() == 1) ) { 
                kaon_D++;
                K_p4.SetPtEtaPhiM(daughter->pt(),daughter->eta(),daughter->phi(),daughter->mass());
              }

              // Check if daughter is a ccbar resonance
              else if ( (abs(daughter->pdgId())==resonance_id) && (daughter->status() == 2) ){
                unsigned int nGrandDaug =  daughter->numberOfDaughters(); 
                cc_p4.SetPtEtaPhiM(daughter->pt(),daughter->eta(),daughter->phi(),daughter->mass());
                //Iterate over the daughtes of the JPsi
                for (size_t j=0; j<nGrandDaug; j++){
                  //j-eth Grandaughter of the B meson
                  const reco::Candidate *grandaughter = daughter->daughter(j);
                  if (abs(grandaughter->pdgId())==13){
                    muon_D++;      
                    // Select as muon1 the one with opposite sign as the B meson (K meson) to extract the angular observable
                    if (charge*grandaughter->charge()<0){
                      Muon1_p4.SetPtEtaPhiM(grandaughter->pt(),grandaughter->eta(),grandaughter->phi(),grandaughter->mass());
                    }
                    else {
                      Muon2_p4.SetPtEtaPhiM(grandaughter->pt(),grandaughter->eta(),grandaughter->phi(),grandaughter->mass());
                    }
                  }    
                  else {
                    if (debug) std::cout << "Other particle in the decay of the JPsi! " << grandaughter->pdgId() << std::endl;
                    TLorentzVector gammaD;
                    gammaD.SetPtEtaPhiM(grandaughter->pt(),grandaughter->eta(),grandaughter->phi(),grandaughter->mass());
                    OthersRes_p4 = OthersRes_p4+gammaD;
                  }
                }
              }

              else if( (abs(daughter->pdgId())==13) && (daughter->status() == 1) ){
                muon_D++;            
                //We are going to save the muon1 as the muon of the opposite sign as the kaon, 
								//   which should be the same as the bu meson
                if (charge*daughter->charge()<0){
                  Muon1_p4.SetPtEtaPhiM(daughter->pt(),daughter->eta(),daughter->phi(),daughter->mass());
                }
                else {
                  Muon2_p4.SetPtEtaPhiM(daughter->pt(),daughter->eta(),daughter->phi(),daughter->mass());
                }
              }
              //Look for any other particle
              else {
                const reco::Candidate * mom__ = daughter->mother();
                if (debug) std::cout << "\n  -->> Other Particle pdgID : "<< daughter->pdgId() << std::endl;
                if (debug) std::cout << "  -->> Other Particle Mother : "<< mom__->pdgId() << "\n" << std::endl;
                  
                TLorentzVector gamma;
                gamma.SetPtEtaPhiM(daughter->pt(),daughter->eta(),daughter->phi(),daughter->mass());
                Others_p4 = Others_p4+gamma;
              }
            }
            daughter_ids.push_back(idsJ);
          
          
          
            if (correctDecay){
              // Here we are creating TLorentzVectors for boosting
              // to CM of dilepton system.  
              math::XYZTLorentzVector muon1J(Muon1_p4.Px(), Muon1_p4.Py(), Muon1_p4.Pz(), Muon1_p4.E());
              math::XYZTLorentzVector muon2J(Muon2_p4.Px(), Muon2_p4.Py(), Muon2_p4.Pz(), Muon2_p4.E());
              math::XYZTLorentzVector kaonJ(K_p4.Px(), K_p4.Py(), K_p4.Pz(), K_p4.E());
              math::XYZTLorentzVector ccJ(cc_p4.Px(), cc_p4.Py(), cc_p4.Pz(), cc_p4.E());
              math::XYZTLorentzVector bmesonJ(B_p4.Px(), B_p4.Py(), B_p4.Pz(), B_p4.E());
              math::XYZTLorentzVector others(Others_p4.Px(), Others_p4.Py(), Others_p4.Pz(), Others_p4.E());
              math::XYZTLorentzVector othersRes(OthersRes_p4.Px(), OthersRes_p4.Py(), OthersRes_p4.Pz(), OthersRes_p4.E());

              // Create the di-muon 4 momentum
              math::XYZTLorentzVector dilepJ = muon1J+muon2J;
              ROOT::Math::Boost dileptonCMBoost(dilepJ.BoostToCM());

              math::XYZTLorentzVector kaonCMJ(  dileptonCMBoost( kaonJ )  );
              math::XYZTLorentzVector ccCMJ(  dileptonCMBoost( ccJ )  );
              math::XYZTLorentzVector muonCM1J(  dileptonCMBoost( muon1J )  );
              math::XYZTLorentzVector muonCM2J(  dileptonCMBoost( muon2J )  );
              math::XYZTLorentzVector bmesonCMJ(  dileptonCMBoost( bmesonJ )  );
              math::XYZTLorentzVector othersCM(  dileptonCMBoost( others )  ); 
              math::XYZTLorentzVector othersResCM(  dileptonCMBoost( othersRes )  ); 

              B_p4CM.SetPxPyPzE(bmesonCMJ.x(), bmesonCMJ.y(), bmesonCMJ.z(), bmesonCMJ.t() ) ;
              K_p4CM.SetPxPyPzE(kaonCMJ.x(), kaonCMJ.y(), kaonCMJ.z(), kaonCMJ.t() ) ;
              cc_p4CM.SetPxPyPzE(ccCMJ.x(), ccCMJ.y(), ccCMJ.z(), ccCMJ.t() ) ;
              Muon1_p4CM.SetPxPyPzE(muonCM1J.x(), muonCM1J.y(), muonCM1J.z(), muonCM1J.t() ) ;
              Muon2_p4CM.SetPxPyPzE(muonCM2J.x(), muonCM2J.y(), muonCM2J.z(), muonCM2J.t() ) ;
              Others_p4CM.SetPxPyPzE(othersCM.x(), othersCM.y(), othersCM.z(), othersCM.t() ) ;
              OthersRes_p4CM.SetPxPyPzE(othersResCM.x(), othersResCM.y(), othersResCM.z(), othersResCM.t() ) ;


              costhetaLJ = ( muonCM1J.x()*muonCM2J.x() 
                                 + muonCM1J.y()*muonCM2J.y() 
                                 + muonCM1J.z()*muonCM2J.z() ) / (muonCM1J.P()*muonCM2J.P() );

              costhetaKLJ = ( muonCM1J.x()*kaonCMJ.x()
                                 + muonCM1J.y()*kaonCMJ.y()
                                 + muonCM1J.z()*kaonCMJ.z() ) / (muonCM1J.P()*kaonCMJ.P() );
            }          
      }
    }
   
    bplus=bplus_;
  

  }
 
    tree_->Fill();

    //daughter_id.clear();
    daughter_ids.clear();
    ancestors.clear();

 
}


// ------------ method called once each job just before starting event loop  ------------
void
MCanalyzerResonant::beginJob()
{
  std::cout << "Beginning analyzer job" << std::endl;

  edm::Service<TFileService> fs;
  tree_ = fs->make<TTree>("ntuple","B+->K+ mu mu ntuple");

  //Lab frame momenta  
  tree_->Branch("B_p4",      "TLorentzVector",  &B_p4);
  tree_->Branch("K_p4",      "TLorentzVector",  &K_p4);
  tree_->Branch("cc_p4",      "TLorentzVector",  &cc_p4);
  tree_->Branch("Muon1_p4",  "TLorentzVector",  &Muon1_p4);
  tree_->Branch("Muon2_p4",  "TLorentzVector",  &Muon2_p4);
  tree_->Branch("Others_p4", "TLorentzVector",  &Others_p4);
  tree_->Branch("OthersRes_p4", "TLorentzVector",  &OthersRes_p4);
 
  //CM dimuon momenta  
  tree_->Branch("B_p4CM",      "TLorentzVector",  &B_p4CM);
  tree_->Branch("K_p4CM",      "TLorentzVector",  &K_p4CM);
  tree_->Branch("cc_p4CM",      "TLorentzVector",  &cc_p4CM);
  tree_->Branch("Muon1_p4CM",  "TLorentzVector",  &Muon1_p4CM);
  tree_->Branch("Muon2_p4CM",  "TLorentzVector",  &Muon2_p4CM);
  tree_->Branch("Others_p4CM", "TLorentzVector",  &Others_p4CM);
  tree_->Branch("OthersRes_p4CM", "TLorentzVector",  &OthersRes_p4CM);
  
    
  tree_->Branch("daughter_ids",   "vector", &daughter_ids);
  tree_->Branch("number_daughters",  &number_daughters);
  tree_->Branch("ancestors",   "vector", &ancestors);
    
  tree_->Branch("costhetaLJ",  &costhetaLJ);
  tree_->Branch("costhetaKLJ",  &costhetaKLJ);

  tree_->Branch("Nbplus", &bplus);

	tree_->Branch("run", &run);
	tree_->Branch("luminosityBlock", &luminosityBlock);
	tree_->Branch("event", &event);
}

// ------------ method called once each job just after ending the event loop  ------------
void
MCanalyzerResonant::endJob()
{
  tree_->GetDirectory()->cd();
  tree_->Write();
}

// ------------ method fills 'descriptions' with the allowed parameters for the module  ------------
void
MCanalyzerResonant::fillDescriptions(edm::ConfigurationDescriptions& descriptions) {
  //The following says we do not know what parameters are allowed so do no validation
  // Please change this to state exactly what you do use, even if it is no parameters
  edm::ParameterSetDescription desc;
  desc.setUnknown();
  descriptions.addDefault(desc);

  //Specify that only 'tracks' is allowed
  //To use, remove the default given above and uncomment below
  //ParameterSetDescription desc;
  //desc.addUntracked<edm::InputTag>("tracks","ctfWithMaterialTracks");
  //descriptions.addDefault(desc);
}

//define this as a plug-in
DEFINE_FWK_MODULE(MCanalyzerResonant);
