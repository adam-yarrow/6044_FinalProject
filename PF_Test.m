if ~exist('simData','var')
    simData = GenerateSimData(false);
end

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,0);
P0 = diag([1; 0.01; 1; 0.01]); % 1 km pos variance, 10 (m/s)^2 velocity var
Np = 500;

pfResults = Run_PF(Np, simData, P0, mu0);

%% TODO - PF plotting