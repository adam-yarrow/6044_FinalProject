function y = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay)
%{
    xGPS = state of GPS
    xDebris = state of Debris
    xRx = state of reciever
    fT = GPS transmission frequency
%}

cKmPerS = ModelParams('c');

%% Doppler Shift
% Earth frame quantities
Vg = xGPS([2,4]);
Vd = xDebris([2,4]);
Vr = xRx([2,4]);

Pg = xGPS([1,3]);
Pd = xDebris([1,3]);
Pr = xRx([1,3]);

% Unit position vectors (GPS or Rx relative to debris)
eGD = (Pg - Pd) / norm((Pd - Pg)); % vector from GPS to Debris
eRD = (Pr - Pd) / norm((Pr - Pd)); % vector from debris to Rx

Vdg = dot((Vd - Vg),eGD); % range rate of debris relative to GPS
Vrd = dot((Vd - Vr), eRD); % Velocity of debris relative to Rx projected onto unit vector from Debris to Rx

y(1,1) = (fT/cKmPerS) * (Vdg + Vrd); 



%% TODO - add noise model

%% Time of Flight
if fIncludeTimeDelay
    y(2,1) =  (abs(Pd - Pg) + abs(Pr - Pd)) / cKmPerS;
end
end