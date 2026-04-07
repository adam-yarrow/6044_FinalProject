function [xkp1] = sampleIS_Distribution(xk, dT, debrisParam)
    %{
        Samples the importance sampling distribution for the debris
        problem.
        
        What if i sample processNoise distribution, then propagate through
        the dynamics with the given dT? Technically this is equivalent to
        getting a mean value and drawing from a gaussian at this mean?
    %}

    % Sample Noise
    Sw = chol(debrisParam.W);
    processNoise = debrisParam.gamma * Sw * randn(size(Sw,1),1);

    % Push noise through dynamics
    [xkp1] = OrbitalDynamics(0,xk,dT,processNoise);
end