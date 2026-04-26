%{
    Attempts to run a psuedo NEES test for PF. 
    
    TODO - need to work out if I need to vary the IC too
%}
rngSeed = 100;
nMC = 100;
alpha = 0.05;
nWorkers = 6;
Np = 1000;

params = ModelParams();
params.endTime = 500;
% processNoiseInflationSF = 10;
% dopplerInflationSF = 1;
% deltaTInflationSF = 25;


% params.est.pf.processNoiseCov = params.debris.W * processNoiseInflationSF;
% dopplerMeasStdDev = sqrt(30); % Hz - see paper by Kassas and Khairallah, 2023
% timeOfFlightStdDev =  sqrt(3E-16)*1E6; % microseconds (TODO MAYBE too small, could also do a range based sigma estimate)
% params.est.pf.measNoiseCov = diag([dopplerMeasStdDev^2*dopplerInflationSF;...
%                                     timeOfFlightStdDev^2*deltaTInflationSF]);

params.fEnableProgressBars = false;
[mu0, P0] = makePriorDistribution(params);

% Warm start with NLS
[x0Est_NLS, P_NLS, ~] = NLS_WarmStart();

mu0(2) = x0Est_NLS(2);
mu0(4) = x0Est_NLS(4);

% Update only pure velocity terms in covariance matrix
P0(2,2) = P_NLS(2,2);
P0(2,4) = P_NLS(2,4);
P0(4,4) = P_NLS(4,4);
P0(4,2) = P_NLS(4,2);

neesData = PF_NEES(nMC, rngSeed, nWorkers, params, mu0, P0, Np);

%% Plotting
r1_ind = chi2inv(alpha/2, params.nStates);
r2_ind = chi2inv(1-alpha/2, params.nStates);

% Average NEES bounds (chi2 with MC_Runs*nStates DOF, scaled)
r1_avg = chi2inv(alpha/2, nMC*params.nStates) / nMC;
r2_avg = chi2inv(1-alpha/2, nMC*params.nStates) / nMC;

figure('Name', 'NEES Consistency Test');
subplot(1,2,1);
hold on;
plot(neesData.t, neesData.neesHistory, 'bo', 'MarkerFaceColor', 'b'); 
yline(r1_ind, 'r--', 'Lower Bound (individual)');
yline(r2_ind, 'r--', 'Upper Bound (individual)');
title('NEES Statistic History')
grid on;
ylabel('NEES Statistic');
xlabel('Time (s)')

subplot(1,2,2);
hold on;
plot(neesData.t, neesData.averageNEES, 'bo', 'MarkerFaceColor', 'b'); 
yline(r1_avg, 'r--', 'Lower Bound (average)');
yline(r2_avg, 'r--', 'Upper Bound (average)');
title('Average NEES Statistic');
grid on;
xlabel('Time (s)');
ylabel('Average NEES Statistic')
