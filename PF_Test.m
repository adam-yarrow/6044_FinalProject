params = ModelParams();
if ~exist('simData','var')
    % load('SavedData\simData_halfOrbit.mat')    
    simData = GenerateSimData(false, params);
end
% save('SavedData\simData_halfOrbit.mat','simData');

rng(0);

% mu0 = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
% P0 =  diag([1E-3; 0.1E-3; 1E-3; 0.1E-3]);
[mu0, P0] = makePriorDistribution(params);
Np = 1000;

% profile on 
type = 'RPF';
nWorkers = 0; % 0 --> serial, > 1 --> Parallel pools
pfResults = Run_PF(type, Np, simData, P0, mu0, nWorkers);
% profile viewer;

plotPF_Results(simData,pfResults);
