function [x_kp1, w_kp1_Normalized, est, w_kp1] = SIR_PF(x_k, w_k, y_kp1, q)
%{
    x_k = nStates x N particles
    w_k = N x 1 weights, unused because renormalize each loop
    y_kp1 = measurements
    q = transition distribution function q = f(x_k) = p(x_kp1|x_k)
%}
    [nStates, N] = size(x_k);
    x_kp1 = NaN(nStates,N);
    w_kp1 = NaN(N,1);

    % Sample q(x_kp1|x_k,y_kp1) to get new x_kp1^i
    for iParticle = 1:N
        % Draw a single sample from q(xkp1|xk,i) 
        x_kp1(:,iParticle) = q(x_k(:,iParticle));

        % Get a new w_k = p(z_kp1 | x_kp1)
        w_kp1(iParticle) = pYgivenX(x_kp1(:,iParticle), y_kp1);
    end

    % Normalize weights
    wTot = sum(w_kp1);
    w_kp1_Normalized = w_kp1 ./ wTot;

    % Estimators
    % MMSE
    est.MMSE = x_kp1 * w_kp1_Normalized; % Sum of weights * states
    est.cov = zeros(nStates,nStates);
    for iParticle = 1:N
        est.cov = est.cov + w_kp1_Normalized(iParticle)*...
            ((x_kp1 - est.MMSE)'*(x_kp1 - est.MMSE));
    end

    % MAP
    [~, mapIdx] = max(w_kp1); % Find argmax over all particles
    est.MAP = x_kp1(:,mapIdx);

    % Resampling - draw new particles from approx posterior given by
    % w_kp1_Normalized = p(x_k+1 | Y_1:k+1)
    x_kp1 = randsample(x_kp1,N,true,w_kp1_Normalized);

    % Uniform weights after resampling
    w_kp1_Normalized = 1/N; 
        
end