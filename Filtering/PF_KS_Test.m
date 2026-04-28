function [dt_history, dtMean, testStatistic,varDmean_t,Dt_mu] = PF_KS_Test(simData, pfResults, params,nWorkers)
    % Based off paper: "Assessment of Nonlinear Dynamic Models by KS
    % Statistics", Djuric and Miguez, 2010
    nTimes = numel(pfResults.t);

    Np = size(pfResults.w,1);
    J = 1000; % Paper uses the same number for J as the number of particles
    K = 5; % K must be odd, 3 or 5 should work
 

    nMeasVars = size(simData.meas.y,1);
    fIncludeTimeDelay = (nMeasVars == 2);

    % Mean and variance of D_t (for odd K)
    Dt_mu = (3*K+1)/(4*K);
    Dt_var = (K^3 + 3*K^2 - K - 3)/(48*K^2*(K+1));

    fTruthModel = false; 
    fDopplerGating = false;

    nRx = params.rx.nRx;
    nGPS = params.gps.nSatellites;
    nSensorCombs = nRx*nGPS;
    dt_history = NaN(nMeasVars, nSensorCombs, nTimes); % At each time get different number of measurements
    dtMean = NaN(nMeasVars, nSensorCombs, nTimes);
    testStatistic = NaN(nMeasVars, nSensorCombs, nTimes); % This should be distributed with 0 mean and variance of varDmean_t
    % Dmean_t = NaN(nMeasVars, nTimes); % This is distributed approximately gaussianly with a zero mean and Dt_var
    varDmean_t = NaN(nTimes,1);


    t0 = tic();
    wb = progressBar(1,nTimes,t0,[],'Running PF KS Test');
    for t = 1:nTimes
        varDmean_t(t) = Dt_var/t;
        
        % Resample J particles (TODO - is this correct?)
        indicesToSampleFrom = randsample(1:Np,J,true,pfResults.wNormalized(:,t)');
        x_t = pfResults.x(:,indicesToSampleFrom,t);

        % NEED TO DO THIS FOR EVERY MEASUREMENT RX-GPS Pair
        timeIdx = find(simData.meas.gpsEmissionTime == pfResults.t(t));
        y = simData.meas.y(:,timeIdx);
        xGPS = simData.meas.xGPS(:,timeIdx);
        xRx = simData.meas.xRx(:,timeIdx);

        rxIds = simData.meas.rxId(timeIdx);
        gpsIds = simData.meas.gpsId(timeIdx);

        nMeasurements = size(y,2);
        
        % Process every measurement
        for iMeas = 1:nMeasurements
            currentMeasId = rxIds(iMeas) * gpsIds(iMeas);

            y_tilde = zeros(nMeasVars,K);
            % Generate K fake observations
            for k = 1:K
                y_tilde_k = zeros(nMeasVars,1);
                parfor (j = 1:J, nWorkers)                   
                    y_tilde_k = y_tilde_k +...
                        measurementModel(params.gps.L1freq, xGPS(:,iMeas), ...
                            x_t(:,j), xRx(:,iMeas), fIncludeTimeDelay,...
                            fTruthModel, ...
                            fDopplerGating,...
                            params);
                end
                y_tilde(:,k) = y_tilde_k / J;
            end

            % Get KS Distance
            dt = ksDistance(y(:,iMeas), y_tilde);

            % Save Relevant statistics
            dt_history(:,currentMeasId,t) = dt;
            dtMean(:,currentMeasId,t) = mean(dt_history(:,currentMeasId,:),3,'omitnan');
            testStatistic(:,currentMeasId,t) = abs(dtMean(:,currentMeasId,t) ...
                                                - Dt_mu);
            
        end
        % Dmean_t(:,t) = mean(testStatistic, 2,'omitnan'); 

        wb = progressBar(t, nTimes, t0, wb);        
        if isfield(wb, 'cancelled') && wb.cancelled
            fprintf('Loop cancelled at iter %d\n', k);
            break
        end
    end
    

    %% Plotting
    figure();
    subplot(1,2,1);
    plot(pfResults.t, squeeze(dtMean(1,:,:)),'r*');

    subplot(1,2,2);
    plot(pfResults.t, squeeze(dtMean(2,:,:)),'r*');



end

function d = ksDistance(y, y_tilde)
    K = size(y_tilde,2);

    % CDF of y_tilde evaluated at y_observation
    G_hat = sum(y_tilde <= y, 2) / K; % Doing time of flight and frequency independently

    d = max(G_hat, 1-G_hat);
end