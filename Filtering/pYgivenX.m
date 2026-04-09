function p = pYgivenX(xk, yk, const, R, fUseLogSpace)
%{
    Likelihood function for a given measurement vector y, given a debris
    state, GPS state and Rx state.
    
    xK = [xDebris];
    yk = measurements vector: 9/10 x Nmeasurements [[yDoppler, yDt, xGPS, xRx]^T, ...]
    const = ModelParams()
    R = measurement noise covariance to use
    fUseLogSpace = flag to turn off or on log probability
%}

if nargin < 5
    fUseLogSpace = false;
end


nStates = const.nStates;
nMeasVars = size(R,1);

% Extract relevant states
y = yk(1:nMeasVars,:); % Actual measurements, not just state truth values

gpsIdxStart = nMeasVars+1;
gpsIdxEnd = gpsIdxStart+nStates-1;
xGPS = yk(gpsIdxStart:gpsIdxEnd, :);

rxIdxStart = gpsIdxEnd+1;
xRx = yk(rxIdxStart:end,:);

nMeasurements = size(yk,2);

%% Process all measurements as if they were IID
pVect = NaN(nMeasurements,1);
if fUseLogSpace
    p =0;
else
    p = 1;
end

for iMeas = 1:nMeasurements  
    pVect(iMeas) = getSingleMeasProbability(y(:,iMeas), xGPS(:,iMeas), xk, ...
            xRx(:,iMeas), R, const);

    % Process in log or linear space
    if fUseLogSpace
        p = p + log(pVect(iMeas));
    else
        p = p*pVect(iMeas);
    end
end
end

%% Function to get likelihood for a single measurement
function p = getSingleMeasProbability(yk, xGPS, xDebris, xRx, R, const)
    fIncludeTimeDelay = size(R,1) == 2; % True if Rtrue is 2x2
    
    fT = const.gps.L1freq;

    %% Get Estimated yk = h(xk)
    fTruthModel = true;
    fDopplerThresholdActive = false; % Want to generate valid pdf's even if the yHat is within the threshold
    %% TODO - decide if this is appropriate to set fDopplerThresh = false??
    yHat = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay, ...
        fTruthModel, fDopplerThresholdActive, const);
 
    %% Likelihood
    %{
     Assuming deltaT and doppler measurements are independent.
     Assuming dT from the sim rate for band limiting the white noise
     Assuming the truth covariances.
    %}
   
    % Get raw joint distribution probability
    p = mvnpdf(yk,yHat,R); % y_k ~ N(h(x_k), Rtrue)
    %% TODO - should we adjust gaussian pdf so that dT can't be less than zero?
end