function neesData = PF_NEES(nMC, rngSeed, nWorkers, params, mu0, P0, Np)
    %{
        Ideally use the same warm start from NLS for all simulations.
    %}

    % Data Storage
    simData = cell(nMC,1);
    pfResults = cell(nMC, 1);

    nTimes = params.endTime+1; % assuming GPS rate of 1 Hz
    times = 0:1:nTimes-1;
    neesHistory = NaN(nTimes,nMC); 
    errorHistory = NaN(params.nStates,nTimes,nMC);

    rng(rngSeed);

    for iMC = 1:nMC       
        fprintf('Monte Carlo run %d of %d\n', iMC, nMC);

        tStart = tic;
        % Run Sim - No change to Initial condition
        simData{iMC} = GenerateSimData(false, params);

        %% TODO - should i perturb the mu0 given to the PF?
        type = 'RPF';       
        pfResults{iMC} = Run_PF(type, Np, simData{iMC}, P0, mu0, nWorkers, params);

        measTimesIdx = ismembertol(simData{iMC}.t, pfResults{iMC}.t,1E-9);

        % NEES Stats
        currentError = pfResults{iMC}.xMMSE - simData{iMC}.truth.debris(:,measTimesIdx);
        errorHistory(:,:,iMC) = currentError;
        for iTime = 2:size(currentError,2)
            neesHistory(iTime,iMC) = currentError(:,iTime)' * (pfResults{iMC}.xCov(:,:,iTime) \ currentError(:,iTime));
        end

        tEnd = toc;

        fprintf('Run time = %d (s)\n',tEnd - tStart);
    end

    % Average Stats
    averageNEES = mean(neesHistory,2,'omitnan');
    averageErrors = mean(errorHistory,3,'omitnan');

    %% Data Packaging
    neesData = struct();
    neesData.averageNEES = averageNEES;
    neesData.averageErrors = averageErrors;
    neesData.t = times;
    neesData.neesHistory = neesHistory;
    neesData.errorHistory = errorHistory;   
end