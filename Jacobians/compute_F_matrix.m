function F = compute_F_matrix(x_state, dt)
    mu = 3.986e5; % Earth's gravitational parameter (km^3/s^2)
    
    X = x_state(1);
    Y = x_state(3);
    
    r = sqrt(X^2 + Y^2);
    
    F = zeros(4, 4);
    
    % Position derivatives
    F(1, 2) = 1; % dX/dX_dot
    F(3, 4) = 1; % dY/dY_dot
    
    % Acceleration partials
    F(2, 1) = -(mu / r^3) + (3 * mu * X^2 / r^5);
    F(2, 3) = (3 * mu * X * Y) / r^5;
    
    F(4, 1) = (3 * mu * X * Y) / r^5;
    F(4, 3) = -(mu / r^3) + (3 * mu * Y^2 / r^5);
    
    % Discretization
    F = eye(4) + F * dt; 
end