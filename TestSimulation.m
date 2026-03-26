
debrisIC = createCircularOrbitIC(400,0);
endTime = 9000;

simData = Simulation([0], [pi/2], debrisIC, endTime);


% TODO - make a plot that shows lines eminating between Rx and Tx etc when
% they are in view of one another