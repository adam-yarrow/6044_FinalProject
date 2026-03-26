function simData = Simulation(thetaIC_GPS, thetaIC_Rx, debrisIC, endTime)
%{
    Function to run and generate simulation data that can then be fed 
    through filters.

    thetaIC_GPS = vector of initial GPS angles to initialize the GPS
    constellation with [rad]
    
    thetaIC_Rx = vector of initial reciever angles to initialize Rx
    constellation with [rad]

    debrisIC = vector of initial conditions for debris 4xN

    endTime = time in seconds to end the simulation
%}
    params = ModelParams();

    %% Data Storage Setup
    simData = struct();
    simData.t = 0:params.dT:endTime;
    simData.nTimes = numel(simData.t);    

    simData.nDebris = size(debrisIC,2);
    simData.nGPS = numel(thetaIC_GPS);
    simData.nRx = numel(thetaIC_Rx);

    % Truth States
    simData.debrisState = NaN(params.nStates,simData.nTimes,simData.nDebris);
    simData.gpsState = NaN(params.nStates,simData.nTimes,simData.nGPS);
    simData.rxState = NaN(params.nStates,simData.nTimes,simData.nRx);

    % Raw Msg Storage


    % Processed Measurements
    
    %% Build Objects
    [gpsObjs, rxObjs, debrisObjs] = ...
            buildObjects(simData, params, thetaIC_GPS, thetaIC_Rx, debrisIC);

    %% Run Simulation
    t0 = tic();
    wb = progressBar(1,simData.nTimes,t0,[]);
    for iTime = 1:simData.nTimes
        % Update Dynamics
        simData.gpsState(:,iTime,:) = updateDynamics(gpsObjs);
        simData.debrisState(:,iTime,:) = updateDynamics(debrisObjs);
        simData.rxState(:,iTime,:) = updateDynamics(rxObjs);

        % Get Messages



        % Generate Raw Measurements


        % Package Data

        % Update Progress and check for cancellation
        wb = progressBar(iTime, simData.nTimes, t0, wb);
    
        if isfield(wb, 'cancelled') && wb.cancelled
            fprintf('Loop cancelled at iter %d\n', iTime);
            break
        end
    end

end

function truthStates = updateDynamics(objects) % passes objects by reference if handle class
    % Objects = cell array of handle classes that have stepDynamics() and
    % getState()

    nObjects = numel(objects);
    truthStates = NaN(ModelParams('nStates'), nObjects);

    for iObject = 1:nObjects
        currentObj = objects{iObject};

        currentObj.stepDynamics();
        [truthStates(:,iObject), ~] = currentObj.getState();        
    end
end
function [gpsStorage, rxStorage, debrisStorage] = ...
            buildObjects(simData, params, thetaIC_GPS, thetaIC_Rx, debrisIC)
    gpsStorage = cell(simData.nGPS,1);
    rxStorage = cell(simData.nRx,1);
    debrisStorage = cell(simData.nDebris,1);
    
    for iGPS = 1:simData.nGPS
        gpsIC = createCircularOrbitIC(params.gps.altitude,thetaIC_GPS(iGPS));
        gpsStorage{iGPS} = GPS(iGPS,gpsIC);        
    end
    
    for iRx = 1:simData.nRx
        rxIC = createCircularOrbitIC(params.rEarth,thetaIC_Rx(iRx));
        rxStorage{iRx} = Receiver(iRx,rxIC);
    end

    for iDebris = 1:simData.nDebris 
        debrisStorage{iDebris} = Debris(iDebris,debrisIC(:,iDebris));
    end
end

