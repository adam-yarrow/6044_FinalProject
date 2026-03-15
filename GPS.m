classdef GPS < handle
    % GPS Model Class

    properties
        % Internal States
        x; % state vector
        t; % Time (seconds)
        clockCountsSinceLastEmit;
      
        % Properties
        id;
        emitRate; % Hz (for sending a GPS packet)
        L1; % GPS carrier frequency
        dT;

    end

    methods 
        %{
            Constructor
        %}
        function obj = GPS(id, gpsRate, x0, dT)
            obj.x = x0;
            obj.t = 0;
            obj.id = id;
            obj.emitRate = gpsRate;
            obj.L1 = 1575.42E6; % Hz 
            obj.dT = dT;
            obj.clockCountsSinceLastEmit = 0;

            % TODO - work out if want to use L1 or CA code? which one gets
            % doppler shifted.
        end

        %{
            Step Dynamics
        %}
        function step(obj)
            % Propagate dynamics
            obj.t = obj.t + obj.dT;
        end


        %{
            Emit GPS packet
        %}
        function gpsPacket = emitMsg(obj)
            gpsPacket = struct();
            % Emit GPS if elapsed time meets emission rate
            if (obj.clockCountsSinceLastEmit * obj.dT) >= 1/obj.emitRate
                gpsPacket.id = obj.id;
                gpsPacket.x = obj.x;
                gpsPacket.carrierFreq = obj.L1;
                
                obj.clockCountsSinceLastEmit = 0;
            end
        end

        %{
            Debugging Help
        %}
        function [x,t] = getState()

        end

    end
end