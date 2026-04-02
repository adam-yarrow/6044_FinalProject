function [xIC] = createCircularOrbitIC(altitude, theta)
    mu = ModelParams('mu');
    r = ModelParams('rEarth') + altitude;
    speed = sqrt(mu/r^3)*r;

    xIC = [r*cos(theta);
           -speed*sin(theta);
           r*sin(theta);
           speed*cos(theta)];
end