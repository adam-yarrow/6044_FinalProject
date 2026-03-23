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
     



            %% TODO - flesh this out
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

    end
end