%% Testing GPS
gpsAlt = ModelParams('gps','altitude');
gpsIC1 = createCircularOrbitIC(gpsAlt,0);
gpsIC2 = createCircularOrbitIC(gpsAlt,pi/2);

% Build GPS objects
GPS1 = GPS(1,gpsIC1);
GPS2 = GPS(2,gpsIC2);

% Run Dynamics
times = 0:ModelParams('dT'):43200/2;
nTimes = numel(times);

xGPS1 = NaN(4,nTimes);
xGPS2 = NaN(4,nTimes);

count = 1;
for tk = times
    GPS1.stepDynamics();
    GPS2.stepDynamics();
    xGPS1(:,count) = GPS1.getState();
    xGPS2(:,count) = GPS2.getState();
    count = count + 1;
end

% Plot Results
figure();
hold on;
plot(xGPS1(1,:),xGPS1(3,:),'r');
plot(xGPS2(1,:),xGPS2(3,:),'b--');
grid on;
axis equal;



