%% Testing GPS
gpsAlt = ModelParams('gps','altitude');
gpsIC1 = createCircularOrbitIC(gpsAlt,0);

debrisIC = createCircularOrbitIC(400,0);
debrisIC(4) = debrisIC(4);

% Build GPS objects
GPS1 = GPS(1,gpsIC1);

% Build Debris objects
Debris1 = Debris(2,debrisIC);

% Run Dynamics
times = 0:ModelParams('dT'):43200/2;
nTimes = numel(times);

xGPS1 = NaN(4,nTimes);
xDebris1 = NaN(4,nTimes);

count = 1;
for tk = times
    GPS1.stepDynamics();
    Debris1.stepDynamics();

    xGPS1(:,count) = GPS1.getState();
    xDebris1(:,count) = Debris1.getState();
    count = count + 1;
end

% Plot Results
figure();
hold on;
plot(xGPS1(1,:),xGPS1(3,:),'r');
plot(xDebris1(1,:),xDebris1(3,:),'b');
grid on;
axis equal;



