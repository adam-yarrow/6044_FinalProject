function [x_kp1, w_kp1_Normalized, est, w_kp1, Ness, wTot] = SIR_PF(x_k, w_k, y_kp1, q)
%{
    x_k = nStates x N particles
    w_k = N x 1 weights, unused because renormalize each loop
    y_kp1 = measurements
    q = transition distribution function q = f(x_k) = p(x_kp1|x_k)

    Doing log space weights to avoid underflow issues
%}
    [nStates, N] = size(x_k);
    x_kp1 = NaN(nStates,N);
    w_kp1 = NaN(N,1);

    const = ModelParams();

    % Check if measurement has time of flight included
    fIncludeTimeDelay = false;
    if size(y_kp1,1) == 10 % e.g. 4 x GPS states + 4 x Rx states + yDoppler + yDt
        fIncludeTimeDelay = true;
    end

    %% Get Measurement Covariance
    R = const.est.pf.measNoiseCov / const.dT; 
    if ~fIncludeTimeDelay
        R = R(1,1); % pull out doppler covariance only
    end

    % Sample q(x_kp1|x_k,y_kp1) to get new x_kp1^i
    for iParticle = 1:N
        % Draw a single sample from q(xkp1|xk,i) 
        x_kp1(:,iParticle) = q(x_k(:,iParticle));

        % Get a new w_k = p(z_kp1 | x_kp1)
        fUseLogSpace = true;
        w_kp1(iParticle) = pYgivenX(x_kp1(:,iParticle), y_kp1, const, R, ...
            fUseLogSpace);
    end

    % Normalize weights (in log space)
    wTot = LogSumExp(w_kp1);
    if (wTot == -Inf) %% TODO maybe need to do a large negative number check here???
        error('Particle collapse occured');
    end

    w_kp1_Normalized = exp(w_kp1 - wTot); %w_kp1 ./ wTot;
    w_kp1 = w_kp1_Normalized; % Set this so we can see the correct values

    % Estimators
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

    % Effective sample size
    Ness = calcEffectiveSS(w_kp1_Normalized,N);

    % Resampling - draw new particles from approx posterior given by
    % w_kp1_Normalized = p(x_k+1 | Y_1:k+1)
    indicesToSampleFrom = randsample(1:N,N,true,w_kp1_Normalized);
    x_kp1 = x_kp1(:,indicesToSampleFrom);
    % Uniform weights after resampling
    w_kp1_Normalized = 1/N; 
        
end