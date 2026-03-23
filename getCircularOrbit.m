function [x] = getCircularOrbit(t, omega, r0, theta)
%{
    Generates a circular orbit with rotation rate omega (rad/s)
    and phase offset theta at a distance r0 from the centre of the 
    Earth.
%}
    x = [r0*cos(omega*t+theta); 
         -omega*r0*sin(omega*t+theta);
         r0*sin(omega*t+theta); 
         omega*r0*cos(omega*t+theta)];
end