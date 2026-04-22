clear all; close all; clc
%rng(0);
Startup;
%% Options Struct for NLS Solver
nlsOptions = struct();
nlsOptions.maxIterations = 100;
nlsOptions.JnlsRelTol =  1E-8;
nlsOptions.x0Tol = 1E-6;
nlsOptions.maxAlphaIterations = 50;
nlsOptions.alphaRelTol = 1E-4; % Relative change between estimates of optimal alpha that triggers convergence
nlsOptions.minAlpha = 1E-10;
nlsOptions.fAlphaGoldenSearch = true;
nlsOptions.alphaSF = 0.5;

%% NLS Inputs Definition

NLS_Params = ModelParams();
NLS_Params.endTime = 50;
NLS_Params.rx.fImplementDopplerThresholdGating = true;
NLS_Params.fIncludeTimeOfFlight = false;  

% IC for GPS, Rx & Debris
debris_x0_true = createDebrisIC(NLS_Params);
[mu0, P0] = makePriorDistribution(NLS_Params);
debris_x0 = mu0 + chol(P0,'lower')*randn(size(debris_x0_true));

simData = GenerateSimData(false, NLS_Params);

y = simData.meas.y';
tk = simData.meas.time;
GPS_x = simData.meas.xGPS;
Receiver_x = simData.meas.xRx;

N = length(y);

ft = NLS_Params.gps.L1freq;
c = NLS_Params.c;
dT = NLS_Params.dT;
processNoise = NLS_Params.debris.W;

V_NLS = NLS_Params.rx.V(1,1)/dT;
R_NLS = (V_NLS*35)*eye(N);

%%
   
H_NLS = @(debris_x) compute_H_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, c, dT, NLS_Params);
h_NLS = @(debris_x) h_batch_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, dT, NLS_Params);

%% NLS Test Run

[x0, P, details] = NLS(debris_x0,h_NLS,H_NLS,y,R_NLS,nlsOptions);

error = (x0 - debris_x0_true);
disp('Error in Initial State Estimation = ');
disp(error);

%% Plotting

% Plot 1: Estimation of Initial State
figure('Name', 'Estimation of Initial State');
labels = {'x','vx','y','vy'};

for i = 1:length(x0)
    subplot(2,2,i)
    plot(x0(i),'bo'); hold on;
    plot(debris_x0_true(i),'rx');
    ylabel(labels{i})
    legend('Estimated','True')
    grid on;
end

sgtitle('Initial State Comparison')

nlsDetails = details;

plotNLS(nlsDetails,debris_x0_true,tk,x0,y)

%% 1. Propagate your solved x0 over the simulation time
t_vec = simData.t; % Use the full simulation time vector
nSteps = length(t_vec);
x_est_traj = zeros(4, nSteps);
x_est_curr = x0(:); % Your final result from NLS

% We need to propagate step-by-step to match the simulation timestamps
for k = 1:nSteps-1
    x_est_traj(:, k) = x_est_curr;
    dt = t_vec(k+1) - t_vec(k);
    x_est_curr = OrbitalDynamics(t_vec(k), x_est_curr, dt)';
end
x_est_traj(:, end) = x_est_curr;

% 2. Extract True Trajectory
% simData.truth.debris is [4 x nTimes x nDebris]
x_true_traj = squeeze(simData.truth.debris(:, :, 1));

% 3. Plotting Trajectories
figure('Name', 'Orbit Recovery Performance');
labels = {'x [km]', 'v_x [km/s]', 'y [km]', 'v_y [km/s]'};

for i = 1:4
    subplot(2, 2, i);
    plot(t_vec, x_true_traj(i, :), 'r', 'LineWidth', 2); hold on;
    plot(t_vec, x_est_traj(i, :), 'b--', 'LineWidth', 1.5);
    
    xlabel('Time [s]');
    ylabel(labels{i});
    legend('Truth', 'NLS Propagated');
    grid on;
    title(['Trajectory: ', labels{i}]);
end
sgtitle('True vs. Estimated Debris Trajectory (50s Window)');