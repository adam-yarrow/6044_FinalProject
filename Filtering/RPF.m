function [outputs] = RPF(x_k, w_k, y_kp1, q, effectiveParticlesTol, nWorkers, const)
%{
    Regularized PF
    
    x_k = nStates x N particles
    w_k = N x 1 weights
    y_kp1 = measurements
    q = transition distribution function q = f(x_k) = p(x_kp1|x_k)
%}
    status = 0;
    [nStates, N] = size(x_k);
    x_kp1 = NaN(nStates,N);
    w_kp1 = NaN(N,1);

    % Check if measurement has time of flight included
    fIncludeTimeDelay = false;
    nMeasVars = 1;
    if size(y_kp1,1) == 10 % e.g. 4 x GPS states + 4 x Rx states + yDoppler + yDt
        fIncludeTimeDelay = true;
        nMeasVars = 2;
    end

    nMeasurements = size(y_kp1,2);

    yHat = NaN(nMeasVars, nMeasurements, N);

    %% Get Measurement Covariance
    R = const.est.pf.measNoiseCov / const.dT; 
    if ~fIncludeTimeDelay
        R = R(1,1); % pull out doppler covariance only
    end

    % Sample q(x_kp1|x_k,y_kp1) to get new x_kp1^i
    parfor (iParticle = 1:N, nWorkers)
        % Draw a single sample from q(xkp1|xk,i) 
        x_kp1(:,iParticle) = q(x_k(:,iParticle));

        % Get a new w_kp1 = p(z_kp1 | x_kp1)*w_k
        [pLikelihoood, yHat(:,:,iParticle)] = pYgivenX(x_kp1(:,iParticle),...
            y_kp1, const, R, const.est.pf.fUseLogSpace);
        if const.est.pf.fUseLogSpace
            w_kp1(iParticle) = pLikelihoood + log(w_k(iParticle));
        else
            w_kp1(iParticle) = pLikelihoood*w_k(iParticle);
        end
    end

    % Normalize weights
    if const.est.pf.fUseLogSpace
        wTot = LogSumExp(w_kp1);
        if (wTot == -Inf) 
            warning('Particle collapse occured');
            status = 1;
        end
        w_kp1_Normalized = exp(w_kp1 - wTot); %w_kp1 ./ wTot;
    else
        wTot = sum(w_kp1);
        if (wTot == 0)
            warning('Particle collapse occured');
            status = 1;
        end

        w_kp1_Normalized = w_kp1 ./ wTot;
    end
    
    w_kp1 = w_kp1_Normalized; % Set this so we can see the correct values

    %% Estimators
    % MMSE
    est.MMSE = x_kp1 * w_kp1_Normalized; % Sum of weights * states
    est.cov = zeros(nStates,nStates);
    for iParticle = 1:N
        est.cov = est.cov + w_kp1_Normalized(iParticle)*...
            ((x_kp1(:,iParticle) - est.MMSE)*(x_kp1(:,iParticle) - est.MMSE)');
    end

    % MAP
    [~, mapIdx] = max(w_kp1_Normalized); % Find argmax over all particles
    est.MAP = x_kp1(:,mapIdx);

    %% Resampling
    Ness = calcEffectiveSS(w_kp1_Normalized,N);

    if Ness < effectiveParticlesTol*N
        % Standard Resampling - draw new particles from approx posterior given by
        % w_kp1_Normalized = p(x_k+1 | Y_1:k+1)
        indicesToSampleFrom = randsample(1:N,N,true,w_kp1_Normalized);
        x_kp1 = x_kp1(:,indicesToSampleFrom);
                
        % Gaussian Perturbations
        if any(real(eig(est.cov)) <= 1E-18)
            Dk = eye(4); % who knows, terrible sampling
        else
            Dk = chol(est.cov,'lower');
        end
        % A = (4/(nStates + 2))^(1/(nStates+4));
        % hOpt = A*N^-(1/nStates+4); 
        hOpt = const.est.pf.rpf_h;
        x_kp1 = x_kp1 + hOpt*Dk*randn(size(x_kp1));

        % Uniform weights after resampling
        w_kp1_Normalized = 1/N; 
    end

    %% Package Outputs
    outputs = struct();
    outputs.x = x_kp1;
    outputs.wNormalized = w_kp1_Normalized;
    outputs.w = w_kp1;
    outputs.wTot = wTot;
    outputs.est = est;
    outputs.Ness = Ness;
    outputs.yHat = yHat;
    outputs.status = status;
end