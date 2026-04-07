%% Testing Measurement Model

fT = ModelParams('gps','L1freq');
cKmPerS = ModelParams('c');

% xGPS = [2*cosd(45), -2*sind(45), 2*sind(45), 2*cosd(45)]';
xGPS = [10, 0, 0, 0]';
xDebris = [5, 0, 1, -1]';
xRx = [0,0,0,0]';

fIncludeTimeDelay = false;


y = measurementModel(fT, xGPS, xDebris, xRx, fIncludeTimeDelay, true, ModelParams())
