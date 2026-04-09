if ~exist('simData','var')
    % load('SavedData\simData_halfOrbit.mat')    
    simData = GenerateSimData(false);
end
% save('SavedData\simData_halfOrbit.mat','simData');

rng(0);

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
P0 =  diag([0.001; 0.0001; 0.001; 0.0001]); 1E-10*eye(4);
Np = 1000;

% profile on 
type = 'RPF';
pfResults = Run_PF(type, Np, simData, P0, mu0);
% profile viewer;


plotPF_Results(simData,pfResults);
