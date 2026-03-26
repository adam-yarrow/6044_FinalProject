classdef Receiver < handle
    % Reciever Model Class

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
            Constructor
        %}
        function obj = Receiver(id, x0)
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

            % Update time
            obj.t = obj.t + obj.dT;
        end
   
        %{
            Debugging Help
        %}
        function [x,t] = getState(obj)
            x = obj.x;
            t = obj.t;
        end

        %{
            Get all packets that were reflected from debris.
        %}
        function packets = getRecievedPackets(obj, debrisMsgs, gpsMsgs)
            %% TODO 
            % How to handle times when we don't have GPS packets?
            % Are we filling this with white noise?


            %% TODO - check if we also have line of sight to the GPS itself, otherwise
            %% we can't use a reflected message - might be able to use doppler shift only
            %% if we know what GPS we are recieving from based on codec
            %% Do we exclude any of those messages or deal with this in measurements?
            packets = {};
            for debrisMsg = debrisMsgs
                if hasLineOfSight(obj,debrisMsg.debris.x)
                    recieverPacket = struct();
                    recieverPacket.rx.id = obj.id;
                    recieverPacket.rx.x = obj.x;
                    recieverPacket.rx.t = obj.t;

                    recieverPacket.debris = debrisMsgs.debris;
                    recieverPacket.gps = debrisMsgs.gps;
                    recieverPacket.gps.rxToGpsLineOfSight = ...
                        hasLineOfSight(obj,debrisMsgs.gps.x);

                    % TODO - determine if we are doing any calculations
                    % here or process sensor measurements externally?

                    packets{end+1} = recieverPacket;
                end
            end
        end

        %{
            Calculate line of sight between debris and reciever
        %}
        function fLineOfSight = hasLineOfSight(obj,xSecondBody)
            posR = [obj.x(1); obj.x(3)];
            posSecondBody = [xSecondBody(1); xSecondBody(3)];

            posSecondBodyRelR = posSecondBody - posR;
            eHatReciever =  posR / norm(posR);

            % If dot product of debris pos relative to reciever pos is
            % greater than zero then above the horizon, so line of sight
            % exists
            fLineOfSight = (dot(posSecondBodyRelR,eHatReciever) > 0);

        end
    end
end