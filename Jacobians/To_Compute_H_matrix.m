clc; clear all;

% Define variables
syms x y x_dot y_dot real
pd = [x; y];
vd = [x_dot; y_dot];

syms fT c xg yg xg_dot yg_dot xr yr xr_dot yr_dot real
pg = [xg; yg];
pr = [xr; yr];
vg = [xg_dot; yg_dot];
vr = [xr_dot; yr_dot];

% Calculate Measurement Model and Jacobian
Measurement_Model = -(fT/c)*(((vg-vd)'*((pd-pg)/norm(pd-pg))) + ((vd-vr)'*((pr-pd)/norm(pr-pd))));
Jac_H = jacobian(Measurement_Model, [x, x_dot, y, y_dot]);

disp('Symbolic Jacobian:');
disp(Jac_H);

% Generate the callable numerical function
matlabFunction(Jac_H, 'File', 'compute_H_matrix', ...
    'Vars', {[x; x_dot; y; y_dot], [xg; xg_dot; yg; yg_dot], [xr; xr_dot; yr; yr_dot], fT, c});
% Inputs to the function : x_k, gps_state_k, rx_state_k, fT_val, c_val