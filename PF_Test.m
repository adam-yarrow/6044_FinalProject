if ~exist('simData','var')
    % load('SavedData\simData_halfOrbit.mat')    
    simData = GenerateSimData(false);
end
% save('SavedData\simData_halfOrbit.mat','simData');

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
P0 = 1E-10*eye(4); diag([0.01; 0.0001; 0.01; 0.0001]);
Np = 500;

% profile on 
type = 'RPF';
pfResults = Run_PF(type, Np, simData, P0, mu0);
% profile viewer;


plotPF_Results(simData,pfResults);
