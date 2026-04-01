function const = ModelParams(varargin)
% Build Structure
const = struct();

% Simulation Parameters
const.dT = 0.1; % s
const.rEarth = 6378; % km
const.omegaEarth = 2*pi/86400; % rad/s
const.mu = 398600; % km^3/s^2
const.c = 299792.458; % km/s

const.nStates = 4; 
const.nMeas = []; % TODO - determine if 1 or 2 here?
const.stateNames = {'x','xDot','y','yDot'};
const.stateUnits = {'km','km/s','km','km/s'};

% Meas Model
const.fIncludeTimeOfFlight = false;
const.fTruthMeasModel = false;
if (const.fIncludeTimeOfFlight)
    const.measNames = {'fDoppler','timeOfFlight'};
    const.measUnits = {'Hz','s'};
else
    const.measNames = {'fDoppler'};
    const.measUnits = {'Hz'};
end

% GPS Parameters
const.gps.emitRate = 1; % Hz
const.gps.L1freq = 1575.42E6; % Hz 
const.gps.altitude = 20180; % km
const.gps.nSatellites = 31;

% Debris Parameters
const.debris.altitude = 400; % km
const.debris.fProcessNoise = false;
%% TODO - decide on appropriate process noise
const.debris.W = diag([1E-8,1E-8]); 
const.debris.gamma = [0, 0;
                      1, 0;
                      0, 0;
                      0, 1]; % Process noise only impacts acceleration states


% Receiver Parameters
const.rx.nRx = 13; % Every 30 deg
const.rx.dopplerThreshold = calcDopplerThreshold(const.gps.L1freq,...
                                                 const.rEarth, const.gps.altitude,...
                                                 const.mu, const.c); % |Doppler frequency| in Hz you can't detect
const.rx.pDetection = 1.0; % Probability of detection
%% TODO - decide on these parameters
dopplerMeasStdDev = 25; % Hz - guestimate, can adjust to make problem more or less difficult
timeOfFlightStdDev = 0.01; % s
const.rx.V = diag([dopplerMeasStdDev^2; timeOfFlightStdDev^2]); % doppler (Hz)^2, timeDelay (s)^2

% Clutter Parameters
const.clutter.fClutter = false; % clutter on/off
% TODO - actually implement with poisson model if deemed required




%% Pull out specific parameter if required
nArgs = length(varargin);
if nArgs > 0
    for iArg = 1:nArgs
        const = const.(varargin{iArg});
    end
end
end