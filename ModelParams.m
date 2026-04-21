function const = ModelParams(varargin)
% Build Structure
const = struct();

% Simulation Parameters
const.dT = 0.1; % s
const.rEarth = 6378; % km
const.omegaEarth = 2*pi/86400; % rad/s
const.mu = 398600; % km^3/s^2
const.c = 299792.458; % km/s
const.karmanLine = 100; % km
const.endTime = 6500/4; % seconds

const.fEnableProgressBars = true;

const.nStates = 4; 
const.stateNames = {'x','xDot','y','yDot'};
const.stateUnits = {'km','km/s','km','km/s'};

% Meas Model
const.fIncludeTimeOfFlight = true;
const.fTruthMeasModel = false;
if (const.fIncludeTimeOfFlight)
    const.measNames = {'fDoppler','timeOfFlight'};
    const.measUnits = {'Hz','s'};
    const.nMeas = 2;
else
    const.measNames = {'fDoppler'};
    const.measUnits = {'Hz'};
    const.nMeas = 1;
end

% GPS Parameters
const.gps.emitRate = 1; % Hz
const.gps.L1freq = 1575.42E6; % Hz 
const.gps.altitude = 20180; % km
const.gps.nSatellites = 31;

% Debris Parameters: Assuming Iridium 33-Cosmos 2251 Collision
%{
    Mean deltaV is correlated with covariance
%}
% Actual debris deltaV
const.debris.IC.radialDeltaV = 40/1000; % km/s
const.debris.IC.downRangeDeltaV = 40/1000; % km/s
% Debris distribution (loosely based on paper by Tan, Zhang and Dokhanian)
const.debris.IC.meanDeltaV = [5; 5]/1000; 
const.debris.IC.covDeltaV =  (40/1000)^2*[1 0.5; 0.5 1]; % Should this have off diagonals?
const.debris.IC.covDeltaPos = 0.25/1000; % Based on Gong et al. (2025)
const.debris.altitude = 790; % km (average of apogee and perigee  for Iridium 33)
const.debris.phaseIC = 0; % angle in rad
const.debris.fProcessNoise = true;
accelProcessNoiseStdDev = 1E-6; % (km/s)^2 - from: Fig. 3.1 of "Satellite Orbits - Models Methods Applications" by Montenbruk and Gill
const.debris.W = diag([accelProcessNoiseStdDev^2,accelProcessNoiseStdDev^2]); % (km/s^2)^2
const.debris.gamma = [0, 0;
                      1, 0;
                      0, 0;
                      0, 1]; % Process noise only impacts acceleration states

% Receiver Parameters
const.rx.nRx = 13; % Every 30 deg
const.rx.dopplerThreshold = calcDopplerThreshold(const.gps.L1freq,...
                                                 const.rEarth, const.gps.altitude,...
                                                 const.mu, const.c); % |Doppler frequency| in Hz you can't detect
const.rx.fImplementDopplerThresholdGating = true;

dopplerMeasStdDev = sqrt(30); % Hz - see paper by Kassas and Khairallah, 2023
timeOfFlightStdDev =  sqrt(3E-16)*1E6; % microseconds (TODO MAYBE too small, could also do a range based sigma estimate)
const.rx.V = diag([dopplerMeasStdDev^2; timeOfFlightStdDev^2]); % doppler (Hz)^2, timeDelay (s)^2

%% Filtering parameters
processNoiseInflationSF = 10; %0.1;
const.est.pf.processNoiseCov = const.debris.W * processNoiseInflationSF;
dopplerInflationSF = 35; 50;
deltaTInflationSF = 1000; 100;
const.est.pf.measNoiseCov = diag([dopplerMeasStdDev^2*dopplerInflationSF;...
                                    timeOfFlightStdDev^2*deltaTInflationSF]);

const.est.pf.NessTol = 0.5; % 0 to 1, proportion of Np to resample at
const.est.pf.rpf_h = 0; 1E-5; % IF zero then just SIR filter with resampling based on Ness tolerance
const.est.pf.fUseLogSpace = true;
const.est.pf.type = 'RPF';

% NLS Params
nlsOptions = struct();
nlsOptions.maxIterations = 100;
nlsOptions.JnlsRelTol =  1E-8;
nlsOptions.x0Tol = 1E-6;
nlsOptions.maxAlphaIterations = 50;
nlsOptions.alphaRelTol = 1E-4; % Relative change between estimates of optimal alpha that triggers convergence
nlsOptions.minAlpha = 1E-10;
nlsOptions.fAlphaGoldenSearch = true;
nlsOptions.alphaSF = 0.5;
const.nls.options = nlsOptions;
const.nls.covInflationSF = 35;

%% Pull out specific parameter if required
nArgs = length(varargin);
if nArgs > 0
    for iArg = 1:nArgs
        const = const.(varargin{iArg});
    end
end
end