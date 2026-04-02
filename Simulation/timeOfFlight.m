function [dT] = timeOfFlight(x1,x2)
    %{
      First order approximation of time of flight. Using Euler integration of velocity 
      assuming zero acceleration over the time.

      Assumes that the RF signal is emitted from x1 and recieved at x2.
    %}


    p1 = [x1(1); x1(3)];
    p2 = [x2(1); x2(3)];
    % 
    % v2 = [x2(2); x2(4)];
    % 
    % speedOfLight = ModelParams('c');
    % 
    % a = speedOfLight^2 - v2'*v2;    
    % b = -2*v2'*(p2-p1);
    % c = -(p2-p1)'*(p2-p1);
    % 
    % dT = (-b+sqrt(b^2-4*a*c))/(2*a);

    dT = norm(p1 - p2) / speedOfLight;    
end