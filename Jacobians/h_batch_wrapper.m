function h_k1 = h_batch_wrapper(tk, debris_x0, GPS_x, Receiver_x, ft, dT)
    
    % Inputs:
    % tk            - [N x 1] time vector
    % debris_x0     - [n x 1] initial debris state vector
    % GPS_x         - [n x N] GPS satellite states over time
    % Receiver_x    - [n x N] receiver states over time
    % ft            - scalar or struct (measurement model parameter/flag)
    % dT            - scalar (time step for propagation)
    %
    % Output:
    % h_k1          - [N x 1] predicted measurement vector

    % Initialize debris state
    debris_x = debris_x0;              % [n x 1]

    % Number of time steps
    N = length(tk);

    % Preallocate output
    h_k1 = zeros(N, 1);                % [N x 1]
    const = ModelParams();
    % Time loop
    for k = 1:N
        
        % Extract states at current timestep
        gps_k = GPS_x(:, k);           % [n x 1]
        rx_k  = Receiver_x(:, k);      % [n x 1]
        
        % Compute measurement (assumed scalar output)
        y_k = measurementModel(ft, gps_k, debris_x, rx_k, false, true, true, const);  % [1 x 1]
        
        % Store measurement
        h_k1(k) = y_k;
        
        % Propagate debris state forward
        debris_x = OrbitalDynamics(tk(k), debris_x, dT);   % [n x 1]
    end
end