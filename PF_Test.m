%% Vanilla Sim Data Generation 
% rng(0);
params = ModelParams();
params.endTime = 50;
if ~exist('simDataTest','var') 
    simDataTest = GenerateSimData(false, params);
end

[mu0, P0] = makePriorDistribution(params);
Np = 1000;

%% Warm start with NLS
rng(0);
[x0Est_NLS, P_NLS, ~] = NLS_WarmStart();

mu0(2) = x0Est_NLS(2);
mu0(4) = x0Est_NLS(4);

% Update only pure velocity terms in covariance matrix
P0(2,2) = P_NLS(2,2);
P0(2,4) = P_NLS(2,4);
P0(4,4) = P_NLS(4,4);
P0(4,2) = P_NLS(4,2);

%% Run Filter
type = params.est.pf.type;
nWorkers = 6; % 0 --> serial, > 1 --> Parallel pools
pfResultsTest = Run_PF(type, Np, simDataTest, P0, mu0, nWorkers, params);

plotPF_Results(simDataTest,pfResultsTest,params);

%% KS Test
[dt_history, dtMean, testStatistic,varDmean_t,Dt_mu] =...
        PF_KS_Test(simDataTest, pfResultsTest, params,nWorkers);

plotPF_KS_Test(pfResultsTest, varDmean_t, testStatistic);




