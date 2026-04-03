function [xkp1] = OrbitalDynamics(tk,xk,dT,processNoise)
    %{
        Nonlinear orbital dynamics with no control input.
        processNoise = 4x1 vector corresponding to derivative states (ZOH)   
    %}
    
    if nargin < 4
        processNoise = zeros(ModelParams('nStates'),1);
    end

    mu = ModelParams('mu');
    r = norm([xk(1), xk(3)]);
    % ZOH process noise vector (treating as if it were a control input)
    dx = @(t,x) [x(2); -mu*x(1)/r^3; x(4); -mu*x(3)/r^3] + processNoise;
    
    options = odeset('RelTol',1e-8, AbsTol=1e-8); % Options from 5044, assuming good?
    [~, xTemp] = ode45(dx, [tk,tk+dT], xk, options);
    xkp1 = xTemp(end,:);
end