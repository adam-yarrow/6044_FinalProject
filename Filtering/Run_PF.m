function [outputArg1,outputArg2] = Run_PF(type, Nparticles, yStruct)
    %{
        Runs a PF.
        Options = SIR PF
        yStruct = simData.meas
    %}

    nTimes = yStruct.time
    % Internal PF states
    xPF = NaN(Nparticles, nTimes);    

    

end


function [x_kp1, w_kp1_Normalized, est, w_kp1, pXgivenY] = SIR_PF(x_k, w_k, y_kp1, q, Nx)
    % x_k = N x 1 particles
    % w_k = N x 1 weights, unused because renormalize each loop
    % y_kp1 = measurement
    % q = T matrix (rows = x_kp1, columsn = x_k)

    N = length(x_k);
    x_kp1 = NaN(N,1);
    w_kp1 = NaN(N,1);

    % Sample q(x_kp1|x_k,y_kp1) to get new x_kp1^i
    % q(x_kp1) = p(x_kp1|x_k) = Transition distribution 
    for i = 1:N
        % Draw a single sample from q(xkp1|xk,i) 
        x_kp1(i) = randsample(Nx,1,true,q(:,x_k(i))); % q = T(j = k+1, i = k)

        % Get a new w_k = p(z_kp1 | x_kp1)
        w_kp1(i) = likelihoodZgivenZeta(x_kp1(i), y_kp1, Nx);
    end

    % Normalize weights
    wTot = sum(w_kp1);
    w_kp1_Normalized = w_kp1 ./ wTot;

    % Make Posterior Distribution
    pXgivenY = makePF_PDF(x_kp1,w_kp1_Normalized,Nx);
    pXgivenY = pXgivenY ./ sum(pXgivenY); % Normalize to make a true prob distribution (probably don't need this?)

    
    % Estimators
    % MMSE
    est.MMSE = (1:1:Nx) * pXgivenY;

    % MAP
    [~, est.MAP] = max(pXgivenY); % Find argmax over all particles


    % Resampling - draw new particles from approx posterior given by
    % w_kp1_Normalized = p(x_k+1 | Y_1:k+1)
    x_kp1 = randsample(Nx,N,true,pXgivenY); % TODO - is this correct cause throwing away all of the history???
    w_kp1_Normalized = 1/N; % Uniform weights after resampling
        
end