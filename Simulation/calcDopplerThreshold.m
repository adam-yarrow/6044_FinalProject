function [fThreshold] = calcDopplerThreshold(fT, rE, hGPS, mu, c)
    %{
        Calculates the doppler threshold for debris detection based on reciever
        (GPS) maximum doppler shift.

        E.g. you can't differentiate between debris and GPS doppler shift
        in this frequency band

        Based on work by Mahmud, 2017 (pg 57 of "Observation of Low Earth Orbit 
        Debris using GNSS Radar").
    %}
    
    rGPS = hGPS + rE;
    Tgps = 2*pi*sqrt(rGPS^3/mu); % seconds
    vGPS = 2*pi*rGPS/Tgps;
    
    % Max doppler velocity
    vDM = vGPS*rE/rGPS;
    
    fThreshold = fT * vDM / c; % Hz
end