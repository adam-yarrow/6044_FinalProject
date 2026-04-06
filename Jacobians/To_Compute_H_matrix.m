clc; clear all;

% Define variables
syms x x_dot y y_dot real
debris_state = [x; x_dot; y; y_dot];
pd = [x; y];
vd = [x_dot; y_dot];

syms fT c xg yg xg_dot yg_dot xr yr xr_dot yr_dot real
pg = [xg; yg];
pr = [xr; yr];
vg = [xg_dot; yg_dot];
vr = [xr_dot; yr_dot];

% Calculate Measurement Model and Jacobian
Vgd = ((vd - vg)' * (pd - pg)) / norm(pd - pg);
Vdr = ((vr - vd)' * (pr - pd)) / norm(pr - pd);
Measurement_Model = -(fT/c)*((Vgd) + (Vdr));
Jac_H = jacobian(Measurement_Model, [x, x_dot, y, y_dot]);

disp('Symbolic Jacobian:');
disp(Jac_H);

% Generate the callable numerical function
matlabFunction(Jac_H, 'File', 'compute_H_matrix', ...
    'Vars', {[x; x_dot; y; y_dot], [xg; xg_dot; yg; yg_dot], [xr; xr_dot; yr; yr_dot], fT, c});
% Inputs to the function : debris_state_k, gps_state_k, rx_state_k, fT_val, c_val