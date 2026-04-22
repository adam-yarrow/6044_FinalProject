classdef GPS < handle
    % GPS Model Class

    properties
        % Internal States
        x; % current state vector [posX, velX, posY, velY]
        t; % current time (seconds)
        clockCountsSinceLastEmit;
      
        % Properties
        id;
        emitRate; % Hz (for sending a GPS packet)
        L1; % GPS carrier frequency
        dT;

        const
    end

    methods 
        %{
            Constructor
        %}
        function obj = GPS(id, x0, const)
            gpsParams = const.gps;

            obj.x = x0;
            obj.t = 0;
            obj.id = id;
            obj.emitRate = gpsParams.emitRate;
            obj.L1 = gpsParams.L1freq; % Hz 
            obj.dT = const.dT;
            obj.clockCountsSinceLastEmit = 0;
            obj.const = const;

            % TODO - work out if want to use L1 or CA code? which one gets
            % doppler shifted.
        end

        %{
            Step Dynamics
        %}
        function stepDynamics(obj)
            % Propagate dynamics
            obj.x = OrbitalDynamics(obj.t, obj.x, obj.dT, obj.const);

            % Update time
            obj.t = obj.t + obj.dT;
            obj.clockCountsSinceLastEmit = obj.clockCountsSinceLastEmit + 1;
        end

        %{
            Emit GPS packet. MUST be called after stepDynamics() function
        %}
        function gpsPacket = emitMsg(obj)
            gpsPacket = [];

            %{
                TODO - this assumes that the dT is smaller than the GPS rate 
                and is an integer multiple
            %} 

            % Emit GPS if elapsed time meets emission rate
            if (obj.clockCountsSinceLastEmit * obj.dT) >= 1/obj.emitRate
                gpsPacket = struct();
                gpsPacket.id = obj.id;
                gpsPacket.x = obj.x;
                gpsPacket.t = obj.t;
                gpsPacket.carrierFreq = obj.L1;
                
                obj.clockCountsSinceLastEmit = 0;
            end
        end

        %{
            Debugging Help
        %}
        function [x,t] = getState(obj)
            x = obj.x;
            t = obj.t;
        end

    end
end