function plotSensorsAndTxInView(simData)
    figure('Name','Tx and Rx in View')
    subplot(2,1,1);
    plot(simData.meas.simTime, simData.meas.gpsId,'r*');
    grid on;
    xlabel('Time (s)');
    ylabel('GPS ID');

    subplot(2,1,2);
    plot(simData.meas.simTime, simData.meas.rxId,'r*');
    grid on;
    xlabel('Time (s)');
    ylabel('Rx ID');

    sgtitle('Tx and Rx In View vs Time');    
end