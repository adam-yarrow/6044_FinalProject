classdef EKF < handle
    %EKF Extended Kalman Filter

    properties

        % Constants       
        n; % number of states    
        p; % number of meas
        constants; 

        % Noise Params
        Qkf; % Kalman filter process noise (nxn)
        Rfunc; % Function that returns Rk for a given k

        % State Vars
        xkp1_m;
        xkp1_p;
        xk_p;
    
        ykp1_m;

        Pkp1_p;
        Pk_p;
        Pkp1_m;

        Kkp1;   
        Hkp1;
        Rkp1;

        kp1;
    end

    methods
        %% Constructor
        function obj = EKF(Qkf, Rfunc, x0_p, P0_p, constants)
            %LKF Construct an instance of this class
            %   Detailed explanation goes here
            obj.Qkf = Qkf;
            obj.Rfunc = Rfunc;

            % Init Constants
            obj.n = constants.nStates;
            obj.p = constants.nMeas;
            obj.constants = constants;
            
            % Init States
            obj.xk_p = x0_p;
            obj.Pk_p = P0_p;
            obj.Pkp1_p = P0_p;
            obj.xkp1_p = x0_p;
            obj.kp1 = 0;
        end

        %% Step KF
        % TODO - consolidate input variables. Consider moving generation of
        % Fk and Gk into the constructor?
        function obj = step(obj, k, uk, ykp1, stationIds)
            obj.kp1 = k;

            % Set Old kp1 to k (new timestep)
            obj.xk_p = obj.xkp1_p; 
            obj.Pk_p = obj.Pkp1_p;

            % Predict
            obj = predictor(obj);

            % Correct Conditionally
            if isempty(ykp1)
                obj.xkp1_p = obj.xkp1_m;
                obj.Pkp1_p = obj.Pkp1_m;
                obj.ykp1_m  = [];
            else
                obj = corrector(obj, ykp1, stationIds);
            end
        end

        %% Innovations Cov Matrix
        function Sk = getInnovCov(obj)
            if ~isempty(obj.ykp1_m)
                Sk = obj.Hkp1*obj.Pkp1_m*obj.Hkp1' + obj.Rkp1;
            else
                Sk = [];
            end
        end

        %% Measurement Est
        function ykp1Est = getMeasEst(obj)  
            if ~isempty(obj.ykp1_m)              
                ykp1Est = obj.ykp1_m;
            else
                ykp1Est = [];
            end            
        end

        %% Get Current State
        function [xEst_kp1] = getStateEst(obj)
            xEst_kp1 = obj.xkp1_p;
        end

        %% Get Current Covariance
        function Pest_kp1 = getCovarianceEst(obj)
            Pest_kp1 = obj.Pkp1_p;
        end

        %% Predictor
        function obj = predictor(obj)
            tk = obj.constants.dT * (obj.kp1 - 1);
            [Fk, Omegak] = getFOmega(obj, obj.xk_p);
            obj.xkp1_m = getNonlinear(obj, obj.xk_p);
            obj.Pkp1_m = Fk*obj.Pk_p*Fk' + Omegak*obj.Qkf*Omegak';
            %disp(obj.Pkp1_m)
        end

        %% Corrector
        function obj = corrector(obj, ykp1, stationIds)
            nMeas = numel(ykp1)/obj.p;
            Rcell = repmat({obj.Rfunc(obj.kp1)},1,nMeas);
            obj.Rkp1 = blkdiag(Rcell{:}); % Assuming each measurment is independent

            tkp1 = (obj.constants.dT * obj.kp1);
            
            obj.ykp1_m = getNonlinearMeas(obj, tkp1, obj.xkp1_m, stationIds);
            Hkp1_nd = getCi(tkp1, obj.xkp1_m, obj.constants.rE, obj.constants.omegaE, stationIds);
            obj.Hkp1 = reshape(permute(Hkp1_nd,[1 3 2]), obj.p*size(Hkp1_nd, 3), obj.n);

            obj.Kkp1 = obj.Pkp1_m*obj.Hkp1'*inv(obj.Hkp1*obj.Pkp1_m*obj.Hkp1'+obj.Rkp1);
            obj.xkp1_p = obj.xkp1_m + obj.Kkp1*(ykp1(:) - obj.ykp1_m(:));
            obj.Pkp1_p = (eye(obj.n) - obj.Kkp1*obj.Hkp1)*obj.Pkp1_m;
            %disp(obj.Pkp1_p)
        end

        function [x]  = getNonlinear(obj, x0)
              options = odeset('RelTol',1e-8, AbsTol=1e-8);
              [t, x_full] = ode45(@orbitDynamics, [0, obj.constants.dT], x0, options);
              x = x_full(end, :)'; % Extract the final state from the ODE solution
        end

        function [ykp1] = getNonlinearMeas(obj, t, x, stationIds)
            [ykp1, ~] = getNonlinMeasurements(t, x, obj.constants.rE, obj.constants.omegaE, stationIds);
        end

        function [F, Omegak] = getFOmega(obj, x)
            A = getAfromState(x, obj.constants.mu);
            F = eye(size(A)) + obj.constants.dT * A;
            Omegak = obj.constants.dT * obj.constants.Gamma; 
        end

    end
end