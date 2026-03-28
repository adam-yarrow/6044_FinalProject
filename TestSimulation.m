
debrisIC = createCircularOrbitIC(400,0);
endTime = 1000;

simData = Simulation([0,pi/4], [0], debrisIC, endTime);


% TODO - make a plot that shows lines eminating between Rx and Tx etc when
% they are in view of one another

function plotSim(simData)
    
    
    
end