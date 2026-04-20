

%% First Estimate x0 with NLS (to warm start PF)
%{
    NLS isn't using time of flight information, just trying to improve 
    velocity estimate.
%}

%% NLS warm start
[x0Est_NLS, P_NLS, nlsDetails] = NLS_WarmStart();

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
simData = GenerateSimData(false, params);

% Run PF
Np = 1000;
type = 'RPF';
nWorkers = 6; % 0 --> serial, > 1 --> Parallel pools
pfResults = Run_PF(type, Np, simData, P0, mu0, nWorkers);

plotPF_Results(simData,pfResults);

%% Helper Functions
function [x0Est, P, details] = NLS_WarmStart()
    % Fix random seed
    rng(0);

    NLS_Params = ModelParams();

    % NLS Opts
    nlsOptions = NLS_Params.nls.options;
    
    % Model Opts
    NLS_Params.endTime = 50; % force short time window (maybe radar measurements etc)
    NLS_Params.fIncludeTimeOfFlight = false;
    
    % IC for GPS, Rx & Debris
    debris_x0_true = createDebrisIC(NLS_Params);
    [mu0, P0] = makePriorDistribution(NLS_Params);
    debris_x0 = mu0 + chol(P0,'lower')*randn(size(debris_x0_true));
    
    simData_NLS = GenerateSimData(false, NLS_Params);

    y = simData_NLS.meas.y';
    tk = simData_NLS.meas.time;
    GPS_x = simData_NLS.meas.xGPS;
    Receiver_x = simData_NLS.meas.xRx;
    
    N = length(y);
    
    ft = NLS_Params.gps.L1freq;
    c = NLS_Params.c;
    dT = NLS_Params.dT;
    
    % Covariance inflation
    V_NLS = NLS_Params.rx.V(1,1)/dT;
    R_NLS = (V_NLS*NLS_Params.nls.covInflationSF)*eye(N);
    
    % Wrappers on Models       
    H_NLS = @(debris_x) compute_H_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, c, dT);
    h_NLS = @(debris_x) h_batch_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, dT, NLS_Params);
    
    % Run NLS    
    [x0Est, P, details] = NLS(debris_x0,h_NLS,H_NLS,y,R_NLS,nlsOptions);
end