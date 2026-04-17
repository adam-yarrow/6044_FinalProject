if ~exist('simData','var')
    % load('SavedData\simData_halfOrbit.mat')    
    simData = GenerateSimData(false);
end
% save('SavedData\simData_halfOrbit.mat','simData');

rng(0);

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
P0 =  diag([1E-3; 0.1E-3; 1E-3; 0.1E-3]);
Np = 1000;

profile on 
type = 'RPF';
nWorkers = 6; % 0 --> serial
pfResults = Run_PF(type, Np, simData, P0, mu0, nWorkers);
profile viewer;

alphaCI = 0.05;
plotPF_Results(simData,pfResults,alphaCI);
