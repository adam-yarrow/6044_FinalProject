function simData = GenerateSimData(fPlot)
    params = ModelParams();
    
    % Debris IC - TODO: Add perturbations here
    debrisIC = createCircularOrbitIC(params.debris.altitude,0); % Debris in LEO
    endTime = 200; %6298/2; % Track approx half an orbit
   
    % IC for GPS and Rx
    thetaRx = linspace(0,2*pi,params.rx.nRx);
    thetaGPS = linspace(0,2*pi,params.gps.nSatellites);
    
    % Generation
    simData = Simulation(thetaGPS, thetaRx, debrisIC, endTime);

    %% Plotting
    if fPlot
        skipFrames = 9;
        fPlotTxRx = true;
        plotSimulation(simData,skipFrames,fPlotTxRx);
    end
end

