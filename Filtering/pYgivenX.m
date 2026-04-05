function p = pYgivenX(xk, yk)
%{
    Likelihood function for a given measurement vector y, given a debris
    state, GPS state and Rx state.
    
    xK = [xDebris; xGPS; xRx];
    yk = measurements vector
    t = sim times vector
%}
%% Constants
const = ModelParams();

% Check if measurement has time of flight included
fIncludeTimeDelay = false;
if size(yk) == 2
    fIncludeTimeDelay = true;
end
fTruthModel = true;

fT = const.gps.L1freq;
fDThreshold = const.rx.dopplerThreshold;
fUseDopplerThreshold = const.rx.fImplementDopplerThresholdGating;

nStates = const.nStates;

% Extract relevant states
xk = reshape(xk,nStates,[]);
xDebris = xk(:,1);
xGPS = xk(:,2);
xRx = xk(:,3);
 

%% Get Estimated yk = h(xk)
yHat = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay, fTruthModel);


%% Likelihood
%{
 Assuming deltaT and doppler measurements are independent.
 Assuming dT from the sim rate for band limiting the white noise
 Assuming the truth covariances.
%}
%% TODO - decide if this dT is appropriate here???
Rtrue = ModelParams('rx','V')/ModelParams('dT'); % discrete time band limited noise
if ~fIncludeTimeDelay
    Rtrue = Rtrue(1,1); % pull out doppler covariance only
end

% Get raw joint distribution probability
p = mvnpdf(yk,yHat,Rtrue); % y_k ~ N(h(x_k), Rtrue)

% apply doppler threshold correction if applicable
if fUseDopplerThreshold    
    if abs(yk(1)) <= fDThreshold
        % If inside the failed detection gate --> then get 0 likelihood
        p = 0;
    else
        % Renormalise to account for no detection window of doppler
        % measurements. 
        cdfValues = cdf('Normal',[-fDThreshold, fDThreshold], yHat(1), Rtrue(1,1));
        pNoDetection = cdfValues(2) - cdfValues(1); 

        p = p / (1-pNoDetection); % Rescale the probabilities based on lost mass    
    end
end

end
