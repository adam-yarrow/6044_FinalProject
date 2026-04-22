params = ModelParams();
params.endTime = 500;
% params.est.pf.measNoiseCov = params.est.pf.measNoiseCov / 1000;
if ~exist('simDataTest','var')
    % load('SavedData\simData_halfOrbit.mat')    
    simDataTest = GenerateSimData(false, params);
end
% save('SavedData\simData_halfOrbit.mat','simData');

rng(0);

[mu0, P0] = makePriorDistribution(params);
Np = 1000;

% profile on 
type = params.est.pf.type;
nWorkers = 6; % 0 --> serial, > 1 --> Parallel pools
pfResultsTest = Run_PF(type, Np, simDataTest, P0, mu0, nWorkers, params);
% profile viewer;

plotPF_Results(simDataTest,pfResultsTest,params);

%% KS Test
% [dt_history, dtMean, testStatistic] = PF_KS_Test(simDataTest,pfResultsTest,params,nWorkers);
