function [xkp1] = OrbitalDynamics(tk,xk,dT)
    %{
        Pure nonlinear orbital dynamics with no process noise.
    %}
    mu = ModelParams('mu');
    r = norm([xk(1), xk(3)]);
    dx = @(t,x) [x(2); -mu*x(1)/r^3; x(4); -mu*x(3)/r^3];
    
    options = odeset('RelTol',1e-8, AbsTol=1e-8);
    [~, xTemp] = ode45(dx, [tk,tk+dT], xk, options);
    xkp1 = xTemp(end,:);
end