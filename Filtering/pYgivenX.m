function p = pYgivenX(xk, yk, const)
%{
    Likelihood function for a given measurement vector y, given a debris
    state, GPS state and Rx state.
    
    xK = [xDebris];
    yk = measurements vector: 9/10 x Nmeasurements [[yDoppler, yDt, xGPS, xRx]^T, ...]
    const = ModelParams()
%}
% Check if measurement has time of flight included
fIncludeTimeDelay = false;
nMeasVars = 1;
if size(yk,1) == 10 % e.g. 4 x GPS states + 4 x Rx states + yDoppler + yDt
    fIncludeTimeDelay = true;
    nMeasVars = 2;
end

nStates = const.nStates;

% Extract relevant states
y = yk(1:nMeasVars,:); % Actual measurements, not just state truth values

gpsIdxStart = nMeasVars+1;
gpsIdxEnd = gpsIdxStart+nStates-1;
xGPS = yk(gpsIdxStart:gpsIdxEnd, :);

rxIdxStart = gpsIdxEnd+1;
xRx = yk(rxIdxStart:end,:);

nMeasurements = size(yk,2);

%% Get Measurement Covariance
%% TODO - decide if this dT is appropriate here??? - ALSO need to change this in measurementModel.m
% discrete time band limited noise (emit rate in Hz, hence multiplication
Rtrue = ModelParams('rx','V')/ModelParams('dT'); 
if ~fIncludeTimeDelay
    Rtrue = Rtrue(1,1); % pull out doppler covariance only
end

Rtrue = Rtrue * const.est.pf.covInflationSF;

%% Process all measurements as if they were IID
p = 1;
for iMeas = 1:nMeasurements
    p = p * getSingleMeasProbability(y(:,iMeas), xGPS(:,iMeas), xk, ...
        xRx(:,iMeas), Rtrue, const);
    if p == 0
        % Shortcut for speed
        break;
    end
end
end

%% Function to get likelihood for a single measurement
function p = getSingleMeasProbability(yk, xGPS, xDebris, xRx, Rtrue, const)
    fIncludeTimeDelay = size(Rtrue,1) == 2; % True if Rtrue is 2x2
    
    fT = const.gps.L1freq;
    fDThreshold = const.rx.dopplerThreshold;
    fUseDopplerThreshold = const.rx.fImplementDopplerThresholdGating;

    %% Get Estimated yk = h(xk)
    fTruthModel = true;
    fDopplerThresholdActive = false; % Want to generate valid pdf's even if the yHat is within the threshold
    %% TODO - decide if this is appropriate to set fDopplerThresh = false??
    yHat = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay, ...
        fTruthModel, fDopplerThresholdActive, const);
    
    %% TODO - does this make sense? OR SHould we process this measurement and show it has a tiny probability?
    % Shortcut if estimated measurement is within the no-detection range
    if isempty(yHat)
        p = 0;
        return
    end

    %% Likelihood
    %{
     Assuming deltaT and doppler measurements are independent.
     Assuming dT from the sim rate for band limiting the white noise
     Assuming the truth covariances.
    %}
   
    % Get raw joint distribution probability
    p = mvnpdf(yk,yHat,Rtrue); % y_k ~ N(h(x_k), Rtrue)
    %% TODO - should we adjust gaussian pdf so that dT can't be less than zero?
    
    % apply doppler threshold correction if applicable
    if fUseDopplerThreshold 
        % Renormalise to account for no detection window of doppler
        % measurements. 
        cdfValues = normcdf([-fDThreshold, fDThreshold], yHat(1), Rtrue(1,1));
        pNoDetection = cdfValues(2) - cdfValues(1); 
    
        p = p / (1-pNoDetection); % Rescale the probabilities based on lost mass    
    end
end