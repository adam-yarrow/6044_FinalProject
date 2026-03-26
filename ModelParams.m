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
const.measNames = {'fDoppler'};
const.measUnits = {'Hz'};

% GPS Parameters
const.gps.emitRate = 1; % Hz
const.gps.L1freq = 1575.42E6; % Hz 
const.gps.altitude = 20180; % km

% Debris Parameters?


% Receiver Parameters


%% Pull out specific parameter if required
nArgs = length(varargin);
if nArgs > 0
    for iArg = 1:nArgs
        const = const.(varargin{iArg});
    end
end
end