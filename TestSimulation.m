%% Generate Data
debrisIC = createCircularOrbitIC(10000,0);
endTime = 1000;

% Full Case
thetaRx = linspace(0,2*pi,12+1); % every 30 deg
thetaGPS = linspace(0,2*pi,31); % Assuming 30 GPS satellites visible

% Testing case
thetaRx = [0,pi/2];
thetaGPS = [0,pi/4];

% Generate Sim Data
fRegen = false;
if fRegen || ~exist('simData','var')
    simData = Simulation(thetaGPS,thetaRx, debrisIC, endTime);
end


%% Plotting
skipFrames = 9;
fPlotTxRx = true;
plotSimulation(simData,skipFrames,fPlotTxRx);

% TODO - make a plot that shows lines eminating between Rx and Tx etc when
% they are in view of one another
