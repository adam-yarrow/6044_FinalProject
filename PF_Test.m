if ~exist('simData','var')
    simData = GenerateSimData(false);
end
save('SavedData\simData_halfOrbit.mat','simData');

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,0);
P0 = diag([0.01; 0.0001; 0.01; 0.0001]); % 1 km pos variance, 10 (m/s)^2 velocity var
Np = 1000;

pfResults = Run_PF(Np, simData, P0, mu0);

plotPF_Results(simData,pfResults);