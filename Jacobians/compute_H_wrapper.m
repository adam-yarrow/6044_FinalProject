function H_k1 = compute_H_wrapper(tk, debris_x0, GPS_x, Receiver_x, ft, c, dT)

% Inputs:
% tk           : [N x 1] time vector
% debris_x0    : [n x 1] initial state [X, X_dot, Y, Y_dot] (n=4)
% GPS_x        : [n x N] GPS states at each time step
% Receiver_x   : [n x N] receiver states at each time step
% ft           : scalar (measurement model parameter)
% c            : scalar (speed of light or scaling constant)
% dT           : scalar time step
%
% Output:
% H_k1         : [N x n] stacked measurement Jacobian mapped to initial state

    H_k1 = zeros(length(tk), length(debris_x0)); % [N x n]
    Phi_k1 = eye(4); % [n x n] state transition matrix
    F_k1 = eye(4); % [n x n] system Jacobian
    debris_x = debris_x0; % [n x 1]
    t_current = 0;
    
    for k = 1:length(tk)
        
        if tk(k) > t_current
        debris_x = OrbitalDynamics(t_current, debris_x, tk(k) - t_current);
        t_current = tk(k);
        end
        
        % H_k: [1 x n] measurement Jacobian at current state
        H_k = compute_H_matrix(debris_x(:), GPS_x(:,k), Receiver_x(:,k), ft, c);

        % F_k1: [n x n] system Jacobian
        F_k1 = compute_F_matrix(debris_x, dT);

        % Phi_k1: [n x n] propagated STM
        Phi_k1 = F_k1 * Phi_k1;

        % H_k1(k,:): [1 x n] mapped sensitivity to initial state
        H_k1(k,:) = H_k * Phi_k1;

        % debris_x: [n x 1] propagate state forward
        debris_x = OrbitalDynamics(tk(k), debris_x, dT);

    end

end