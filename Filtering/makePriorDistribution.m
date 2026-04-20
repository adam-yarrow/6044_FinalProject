function [mu0, P0] = makePriorDistribution(params)
    % We know original orbit exactly (pretend TLE's are good)
    xOrigOrbit = createCircularOrbitIC(params.debris.altitude,params.debris.phaseIC);
   
    % say we instantly measure the impact and know there was a mean deltaV
    % change only
    mu0 = xOrigOrbit + [0; 
                        params.debris.IC.meanDeltaV(1); 
                        0; 
                        params.debris.IC.meanDeltaV(2)];
    
    % Lets assume we can pretend we are certain on the position of the
    % satellite at the point of impact to within good GPS precision
    P0 = zeros(4,4);
    P0(1,1) = params.debris.IC.covDeltaPos;
    P0(2,2) = params.debris.IC.covDeltaV(1,1);
    P0(2,4) = params.debris.IC.covDeltaV(1,2);
    P0(3,3) = params.debris.IC.covDeltaPos;
    P0(4,4) = params.debris.IC.covDeltaV(2,2);
    P0(4,2) = params.debris.IC.covDeltaV(2,1);
end