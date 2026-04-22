function simData = GenerateSimData(fPlot, params)
    % Debris IC - TODO: Add perturbations here
    debrisIC = createDebrisIC(params); % Debris in LEO
    
    % IC for GPS and Rx
    thetaRx = linspace(0,2*pi,params.rx.nRx+1); thetaRx(1:end-1);
    thetaGPS = linspace(0,2*pi,params.gps.nSatellites+1); thetaGPS = thetaGPS(1:end-1);
    
    % Generation
    simData = Simulation(thetaGPS, thetaRx, debrisIC, params.endTime, params);

    %% Plotting
    if fPlot
        skipFrames = 9;
        fPlotTxRx = true;
        plotSimulation(simData,skipFrames,fPlotTxRx);
    end
end

