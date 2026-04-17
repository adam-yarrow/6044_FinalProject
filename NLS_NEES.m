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
endTime = 50;
NLS_Params.rx.fImplementDopplerThresholdGating = true;

ft = NLS_Params.gps.L1freq;
c = NLS_Params.c;
dT = NLS_Params.dT;
processNoise = NLS_Params.debris.W;
nStates = NLS_Params.nStates;
V_NLS = NLS_Params.rx.V(1,1)/dT;

%% Monte Carlo Simulation

MC_Runs = 50;

alpha = 0.05;
% Individual NEES bounds (chi2 with nStates DOF)
r1_ind = chi2inv(alpha/2, nStates);
r2_ind = chi2inv(1-alpha/2, nStates);

% Average NEES bounds (chi2 with MC_Runs*nStates DOF, scaled)
r1_avg = chi2inv(alpha/2, MC_Runs*nStates) / MC_Runs;
r2_avg = chi2inv(1-alpha/2, MC_Runs*nStates) / MC_Runs;

nees_hist = zeros(MC_Runs, 1);
err_hist = zeros(MC_Runs, nStates);

% IC for GPS, Rx & Debris
thetaRx = linspace(0,2*pi,NLS_Params.rx.nRx);
thetaGPS = linspace(0,2*pi,NLS_Params.gps.nSatellites);
debris_x0_true = createCircularOrbitIC(NLS_Params.debris.altitude,0);

for i = 1:MC_Runs

    fprintf('Monte Carlo run %d of %d\n', i, MC_Runs);
    
    simData = Simulation(thetaGPS, thetaRx, debris_x0_true, endTime);

    y = simData.meas.y';
    tk = simData.meas.time;
    GPS_x = simData.meas.xGPS;
    Receiver_x = simData.meas.xRx;
    
    N = length(y);

    R_NLS = (V_NLS*35)*eye(N);
    
    H_NLS = @(debris_x) compute_H_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, c, dT);
    h_NLS = @(debris_x) h_batch_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, dT, NLS_Params);

    debris_x0 = debris_x0_true + randn(size(debris_x0_true)).*[10;0.01;10;0.01];

    [x0_NEES, P_NEES, ~] = NLS(debris_x0,h_NLS,H_NLS,y,R_NLS,nlsOptions);

    curr_err = debris_x0_true(:) - x0_NEES(:);
    err_hist(i,:) = curr_err';
    nees_hist(i) = curr_err' * (P_NEES \ curr_err);

end

avg_nees = mean(nees_hist);
avg_err = mean(err_hist);


%% Plotting

figure('Name', 'NEES Consistency Test');
plot(nees_hist, 'bo', 'MarkerFaceColor', 'b'); hold on;
yline(r1_ind, 'r--', 'Lower Bound (individual)');
yline(r2_ind, 'r--', 'Upper Bound (individual)');
yline(nStates, 'k-', 'Ideal NEES', 'LineWidth', 2);

%% % Plot average NEES as horizontal line with its own bounds
% yline(avg_nees, 'm-', 'Avg NEES', 'LineWidth', 2);
% yline(r1_avg, 'g--', 'Lower Bound (avg)');
% yline(r2_avg, 'g--', 'Upper Bound (avg)');
xlabel('Run Number'); ylabel('NEES');
title(['Avg NEES: ', num2str(avg_nees), ' (Target: ', num2str(nStates), ')']);
grid on;