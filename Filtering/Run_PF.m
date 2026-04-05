function [pf] = Run_PF(Np, simData, P0, mu0)
    %{
        Runs a SIR PF with inputs:
            Np = number of particles to run
            simData struct
            P0 = covariance for initial xDebris state
            mu0 = mean state for initial xDebris state
        
        Evaluates the PF at each GPS packet emission time (due to the
        wormhole type approach to time of flight we are implementing). E.g.
        estimating the debris position at each GPS emission time.
    %}

    const = ModelParams();
    gpsPacketTimes = unique(simData.meas.gpsEmissionTime);
    nMeasurements = numel(gpsPacketTimes);
    nTimes = nMeasurements + 1;
    
    %% Data Storage
    pf = struct();
    pf.x = NaN(const.nStates, Np, nTimes);   
    pf.w = NaN(Np, nTimes);
    pf.wNormalized = NaN(Np,nTimes);

    pf.xMMSE = NaN(const.nStates, nTimes);
    pf.xCov = NaN(const.nStates, const.nStates, nTimes);
    pf.xMAP = NaN(const.nStates, nTimes);

    %% Prior Distribution
    pf.x(:,:,1) = generateGaussianX_IC(P0, mu0, Np);
    pf.wNormalized(:,1) = 1/Np;
    pf.w(:,1) = pf.wNormalized(:,1);
            
    %% Propagate Particles
    prevGPStime = 0;
    t0 = tic();
    wb = progressBar(1,nTimes,t0,[]);
    for k = 2:nTimes % Matlab indexing makes this interesting
        kt1 = k - 1;

        % Get relevant measurements at the current GPS packet emission time
        currentGPStime = gpsPacketTimes(k-1); % k-1 as the GPS packet times start from k = 1, which is matlab index 2 
        validTimeIdx = simData.meas.gpsEmissionTime == currentGPStime;
        yk = [simData.meas.y(:,validTimeIdx);
              simData.meas.xGPS(:,validTimeIdx);
              simData.meas.xRx(:,validTimeIdx)];

        % Wrapper for IS distribution
        dT = currentGPStime - prevGPStime;
        q = @(xk) sampleIS_Distribution(xk, dT); % Transition distribution

        % Run PF
        [pf.x(:,:,k), pf.wNormalized(:,k), est_k,  pf.w(:,k)] = ...
            SIR_PF(pf.x(:,:,kt1), pf.wNormalized(:,kt1), yk, q);

        % Extract Estimates
        pf.xMMSE(:,k) = est_k.MMSE;
        pf.xCov(:,:,k) = est_k.cov;
        pf.xMAP(:,k) = est_k.MAP;          

        % Update time
        prevGPStime = currentGPStime;

        % Update Progress and check for cancellation
        wb = progressBar(k, nTimes, t0, wb);
    
        if isfield(wb, 'cancelled') && wb.cancelled
            fprintf('Loop cancelled at iter %d\n', k);
            break
        end
    end  
    

end
