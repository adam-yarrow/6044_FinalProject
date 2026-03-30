function dT = timeOfFlight(x1,x2)
    % Zeroth order approximation of time of flight (ignoring 
    % velocity component of state vector)

    p1 = [x1(1); x1(3)];
    p2 = [x2(1); x2(3)];

    dT = norm(p1 - p2) / ModelParams('c');    
end