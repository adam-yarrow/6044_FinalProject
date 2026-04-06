clear all; close all; clc
rng(0);

%% Options Struct for NLS Solver
nlsOptions = struct();
nlsOptions.maxIterations = 100;
nlsOptions.JnlsRelTol = 1E-8; %1E-16
nlsOptions.x0Tol = 1E-6;
nlsOptions.maxAlphaIterations = 30;
nlsOptions.alphaRelTol = 1E-3; % Relative change between estimates of optimal alpha that triggers convergence
nlsOptions.minAlpha = 1E-10;
nlsOptions.fAlphaGoldenSearch = false;
nlsOptions.alphaSF = 0.5;

%% NLS Inputs Definition

NLS_Params = ModelParams();
endTime = 0.1;

% IC for GPS, Rx & Debris
thetaRx = linspace(0,2*pi,NLS_Params.rx.nRx);
thetaGPS = linspace(0,2*pi,NLS_Params.gps.nSatellites);
debris_x0_true = createCircularOrbitIC(NLS_Params.debris.altitude,0);

debris_x0 = debris_x0_true; %+ randn(size(debris_x0_true)).*[10;0.001;10;0.001];

simData = Simulation(thetaGPS, thetaRx, debris_x0_true, endTime);

y = simData.meas.y';
tk = simData.meas.time;
GPS_x = simData.meas.xGPS;
Receiver_x = simData.meas.xRx;

N = length(y);

V_NLS = NLS_Params.rx.V(1,1);
R_NLS = V_NLS*eye(N);

ft = NLS_Params.gps.L1freq;
c = NLS_Params.c;
dT = NLS_Params.dT;
processNoise = NLS_Params.debris.W;
   
H_NLS = @(debris_x) compute_H_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, c, dT);
h_NLS = @(debris_x) h_batch_wrapper(tk, debris_x, GPS_x, Receiver_x, ft, dT);

%% NLS Test Run

[x0, P, details] = NLS(debris_x0,h_NLS,H_NLS,y,R_NLS,nlsOptions);


%% Plotting

figure;
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