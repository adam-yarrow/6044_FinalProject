%% First Estimate x0 with NLS (to warm start PF)
%{
    NLS isn't using time of flight information, just trying to improve 
    velocity estimate.
%}

%% NLS warm start
if ~exist("x0Est_NLS","var")
    [x0Est_NLS, P_NLS, nlsDetails] = NLS_WarmStart();
end

%% Now Use PF to track entire orbit
% Reset rng to match simulation
rng(0);

params = ModelParams();
% Update covariance estimate and mean
[mu0, P0] = makePriorDistribution(params);
% update velocities from NLS (as NLS doesnt use position fusion --> pos will be bad)
mu0(2) = x0Est_NLS(2);
mu0(4) = x0Est_NLS(4);

% Update only pure velocity terms in covariance matrix
P0(2,2) = P_NLS(2,2);
P0(2,4) = P_NLS(2,4);
P0(4,4) = P_NLS(4,4);
P0(4,2) = P_NLS(4,2);

% Run Sim again (for longer)
if ~exist("simData","var")
    simData = GenerateSimData(false, params);
end

% Run PF
Np = 1000;
type = 'RPF';
nWorkers = 6; % 0 --> serial, > 1 --> Parallel pools
pfResults = Run_PF(type, Np, simData, P0, mu0, nWorkers);

plotPF_Results(simData,pfResults);
