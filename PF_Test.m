if ~exist('simData','var')
    simData = GenerateSimData(false);
end

params = ModelParams();
mu0 = createCircularOrbitIC(params.debris.altitude,0);
P0 = diag([1; 0.001; 1; 0.001]); % 1 km pos variance, 10 (m/s)^2 velocity var
Np = 1000;
%% TODO - probably need to either make P0 a lottttt smaller or inflate the time of flight
%% OR, not use time of flight data?

pfResults = Run_PF(Np, simData, P0, mu0);

%% TODO - PF plotting