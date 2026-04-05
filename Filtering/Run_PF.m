function [pf] = Run_PF(type, Np, simData, P0, mu0)
    %{
        Runs a PF.
            type = SIR_PF
            Np = number of particles to run
            simData struct
            P0 = covariance for initial xDebris state
            mu0 = mean state for initial xDebris state
        
    %}

    const = ModelParams();
    nMeasurements = numel(simData.meas.time); 

    %% Data Storage
    pf = struct();
    pf.x = NaN(const.nStates, Np, nMeasurements);   
    pf.w = NaN(Np, nMeasurements);
    pf.wNormalized = NaN(Np,nMeasurements);

    pf.xMMSE = NaN(const.nStates, nMeasurements);
    pf.xMAP = NaN(const.nStates, nMeasurements);

    % TODO find a way to store the posterior distribution? or approx as a gaussian?
    
    %% Prior Distribution
    pf.x(:,:,1) = generateGaussianX_IC(P0, mu0, Np);
    pf.wNormalized(:,1) = 1/Np;
    pf.w(:,1) = pf.wNormalized(:,1);

            

    %% Propagate Particles
    for k = 2:nMeasurements
        kt1 = k - 1;

        % Wrapper for IS distribution
        q = @(xDebris, yk) pYgivenX([xDebris; ...
                                    simData.meas.xGPS(:,kt1); ...
                                    simData.meas.xRx(:,kt1)], yk);

        %% TODO - add switch case here if we have other PF types
        [] = ...
            SIR_PF(pf.x(:,:,kt1), pf.wNormalized(:,kt1), ...
                zMeasHist(k), q, Nx);

        pf.xMMSE(:,k) = est_k.MMSE;
        pf.xMAP(:,k) = est_k.MAP;       
    end  
    

end
