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
    simData.truth.debris = NaN(params.nStates,simData.nTimes,simData.nDebris);
    simData.truth.gps = NaN(params.nStates,simData.nTimes,simData.nGPS);
    simData.truth.rx = NaN(params.nStates,simData.nTimes,simData.nRx);

    % Raw Msg Storage
    simData.msgs.gps = cell(simData.nTimes,1);
    simData.msgs.debris = cell(simData.nTimes,1);
    simData.msgs.rx = cell(simData.nTimes,1);

    % Processed Measurements
    simData.meas.simTime = []; % Nx1 vector of simulation times (times when GPS emitted)
    simData.meas.time = []; % Nx1
    simData.meas.gpsEmissionTime = []; % Nx1 (Time of GPS packet emission)
    simData.meas.y = []; % vector of measurements
    simData.meas.xGPS = []; % state of the GPS at simTime (e.g. not accounting for motion during transmission time)
    simData.meas.xRx = []; % state of the Rx at simTime
   
    %% Build Objects
    [gpsObjs, rxObjs, debrisObjs] = ...
            buildObjects(simData, params, thetaIC_GPS, thetaIC_Rx, debrisIC);

    %% Run Simulation
    t0 = tic();
    wb = progressBar(1,simData.nTimes,t0,[]);
    for iTime = 1:simData.nTimes
        % Update Dynamics
        simData.truth.gps(:,iTime,:) = updateDynamics(gpsObjs);
        simData.truth.debris(:,iTime,:) = updateDynamics(debrisObjs);
        simData.truth.rx(:,iTime,:) = updateDynamics(rxObjs);

        % Get Messages
        [simData.msgs.gps{iTime}, ...
         simData.msgs.debris{iTime}, ...
         simData.msgs.rx{iTime}] = getMsgs(simData, gpsObjs, debrisObjs, rxObjs);

        % Convert Msgs to Measurement Data
        for iRxMsg = 1:numel(simData.msgs.rx{iTime})
            rxMsg = simData.msgs.rx{iTime}{iRxMsg};
            y = measurementModel(params.gps.L1freq, ...
                                rxMsg.gps.x, rxMsg.debris.x, rxMsg.rx.x,...
                                params.fIncludeTimeOfFlight,...
                                params.fTruthMeasModel);
            
            % y can be empty if outside of doppler threshold
            if ~isempty(y)
                simData.meas.time(end+1) = rxMsg.rx.t; % time of receipt
                simData.meas.simTime(end+1) = simData.t(iTime); % time of emission
                simData.meas.gpsEmissionTime(end+1) = rxMsg.gps.t;
                simData.meas.y(:,end+1) = y;
                simData.meas.xGPS(:,end+1) = rxMsg.gps.x;
                simData.meas.xRx(:,end+1) = rxMsg.rx.x;
            end
            

            %% TODO - add clutter here (e.g. distribution of other returns)
        end

        % Update Progress and check for cancellation
        wb = progressBar(iTime, simData.nTimes, t0, wb);
    
        if isfield(wb, 'cancelled') && wb.cancelled
            fprintf('Loop cancelled at iter %d\n', iTime);
            break
        end
    end

end

function [gpsMsgs, debrisMsgs, rxMsgs] = getMsgs(simData, gpsObjs, debrisObjs, rxObjs)
    % Get All GPS msgs
    gpsMsgs = {};
    for iGPS = 1:simData.nGPS
        currentGpsMsg = gpsObjs{iGPS}.emitMsg();
        if ~isempty(currentGpsMsg)
            gpsMsgs = [gpsMsgs, currentGpsMsg];
        end
    end

    % Reflect GPS off Debris
    % TODO - decide if its appropriate to flatten all messages?
    debrisMsgs = {};
    for iDebris = 1:simData.nDebris
        currentDebrisMsgs = debrisObjs{iDebris}.emitMsg(gpsMsgs);
        if ~isempty(currentDebrisMsgs)
            debrisMsgs = [debrisMsgs, currentDebrisMsgs]; % Flatten (under assumption of single debris?)
        end
    end

    % Get all RX msgs (from multiple debris)
    rxMsgs = {}; 
    for iRx = 1:simData.nRx
        currentRxMsgs = rxObjs{iRx}.getRecievedPackets(debrisMsgs,gpsMsgs);
        if ~isempty(currentRxMsgs)
            rxMsgs = [rxMsgs, currentRxMsgs];      
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
        rxIC = createCircularOrbitIC(0, thetaIC_Rx(iRx));
        rxStorage{iRx} = Receiver(iRx,rxIC);
    end

    for iDebris = 1:simData.nDebris 
        debrisStorage{iDebris} = Debris(iDebris,debrisIC(:,iDebris));
    end
end

