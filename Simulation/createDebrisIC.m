function mu0 = createDebrisIC(params)
    %% Take original circular orbit for Iridium
    xOrigOrbit = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
   
    %% Create debris IC
    % Assuming no change in position, modelling from point of instantaneous
    % impact
    mu0 = xOrigOrbit + [0;
                        params.debris.IC.radialDeltaV; 
                        0; 
                        params.debris.IC.downRangeDeltaV];
end