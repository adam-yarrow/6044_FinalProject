classdef Debris < handle
    %{
        Class of debris objects. Takes GPS signals and returns reflected signals. 
    %}

    properties
        % Internal States
        x; % current state vector [posX, velX, posY, velY]
        t; % current time (seconds) 

        % Properties
        id;
        dT;
    end

    methods
        %{
            Constructs a single piece of debris
        %}
        function obj = Debris(id, x0)
            obj.x = x0;
            obj.t = 0;
            obj.id = id;
            obj.dT = ModelParams('dT');
        end

        %{
            Step Dynamics
        %}
        function stepDynamics(obj)
            % Propagate dynamics
            obj.x = OrbitalDynamics(obj.t, obj.x, obj.dT);


            if ModelParams('debris','fProcessNoise')
                % obj.x = obj.x + TODO;
            end

            % Update time
            obj.t = obj.t + obj.dT;
        end

        % TODO - need to pass into the debris all GPS satelitles
        % Then do angle of incidence checks etc.
        function debrisMsgs = emitMsg(obj, gpsMsgs)
            %{
                gpsMsgs = cell array of gps messages.
            %}
            % Empty set of debris messages
            debrisMsgs = {};

            % Process all GPS messages
            for gpsMsgCell = gpsMsgs       
                gpsMsg = gpsMsgCell{1}; % pull out valid GPS msg
                % Package message if valid
                if  checkLineOfSight(obj, gpsMsg.x)
                    % Time stamp message arrival at Debris
                    delT = timeOfFlight(obj.x, gpsMsg.x);

                    debrisMsg = struct();
                    debrisMsg.debris.id = obj.id;
                    debrisMsg.debris.x = obj.x;
                    debrisMsg.debris.t = obj.t + delT;

                    debrisMsg.gps = gpsMsg;

                    %% TODO - add tumbling dynamics here in future to perturb signal strength

                    debrisMsgs{end+1} = debrisMsg;
                end
            end
        end

        %{
            Debugging Help
        %}
        function [x,t] = getState(obj)
            x = obj.x;
            t = obj.t;
        end

        %{
            Check line of sight
        %}
        function fValidLineOfSight = checkLineOfSight(obj,xGPS)
            rE = ModelParams('rEarth');
            % X = xGPS(1);
            % Y = xGPS(3);
            posGPS = [xGPS(1); xGPS(3)];
            posDebris = [obj.x(1); obj.x(3)];
            posDebrisRelGPS = posDebris - posGPS;

            fValidLineOfSight = true;
            % If dot product in position vectors is less than 0, you are on
            % the opposite side of the earth to the GPS satellite --> check
            % if sheilded by the earth.
            if (dot(posGPS, posDebris) <= 0)
                % Now see if the debris is observable based on angle
                % between GPS and earth radius
                betaCrit = atan2(rE,norm(posGPS));

                % Project the relative position of the debris onto the unit
                % vector from the debris towards the centre of the earth
                adjacent = dot(posDebrisRelGPS, -posGPS/norm(posGPS));
                betaDebris = acos(adjacent/norm(posDebrisRelGPS));
    
                % Within the Earth's eclipse angle for the debris
                if abs(betaDebris) < betaCrit
                    fValidLineOfSight = false;
                end
            end
        end 
    end
end