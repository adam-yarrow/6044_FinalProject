function y = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay,...
    fTruthModel, fDopplerThreshold, const)
%{
    xGPS = state of GPS
    xDebris = state of Debris
    xRx = state of reciever
    All states are at the same time
    fT = GPS transmission frequency
%}


cKmPerS = const.c;

%% Doppler Shift
% Earth frame quantities
Vg = xGPS([2,4]);
Vd = xDebris([2,4]);
Vr = xRx([2,4]);

Pg = xGPS([1,3]);
Pd = xDebris([1,3]);
Pr = xRx([1,3]);

% Unit position vectors (GPS or Rx relative to debris)
eGD = (Pd - Pg) / norm((Pd - Pg)); % vector from GPS to Debris
eRD = (Pr - Pd) / norm((Pr - Pd)); % vector from debris to Rx

Vdg = dot((Vd - Vg),eGD); % range rate of debris relative to GPS
Vrd = dot((Vr - Vd), eRD); % Velocity of Rx relative to debris projected onto unit vector from Debris to Rx

y(1,1) = -(fT/cKmPerS) * (Vdg + Vrd); 

%% Time of Flight
if fIncludeTimeDelay
    % NOTE: this time of flight estimate does not account for transmission
    % time. However, the time we record as the true transmission time is
    % correct
    y(2,1) =  (norm(Pd - Pg) + norm(Pr - Pd)) / cKmPerS * 1E6; % microseconds
end

%% Noise Model
if ~fTruthModel
    % Static Gaussian Noise Model (Ref: Ristic Ch8)
    Rtrue = const.rx.V/const.dT; % discrete time band limited noise - assuming ADC runs at sim rate
    
    %% TODO - need to check if my constant dT approach is correct
    S = chol(Rtrue,'lower');    
    nVars = numel(y);

    S = S(1:nVars,1:nVars); % Only take doppler if no time of flight data
    staticMeasNoise = S * randn(nVars,1);

    % Dynamic Noise Model
    %% TODO - could be a function of distance square
    %% TODO - could be a function of debris orientation
    dynamicMeasNoise = zeros(nVars,1);

    % Total Response
    y = y + staticMeasNoise + dynamicMeasNoise;
end

%% Doppler Detection Threshold
if fDopplerThreshold
    % If doppler measurement is below the threshold throw away all
    % measurements because they can't be distinguished from real GPS
    % measurements
    if abs(y(1,1)) < const.rx.dopplerThreshold
        y = [];
    end
end
end