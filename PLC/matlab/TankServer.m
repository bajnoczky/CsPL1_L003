classdef TankServer < handle
    %TANKSERVER Network endpoint owned by the PLC panel.
    % Call tick regularly to advance the simulation while serving requests.
    properties (SetAccess = private)
        Tank
        Host
        Port
        Running = false
    end
    properties (Access = private)
        Socket = []
        Clock
        LastUpdate = 0
    end
    methods
        function obj = TankServer(host, port)
            arguments
                host (1,1) string = "127.0.0.1"
                port (1,1) double {mustBeInteger,mustBePositive,mustBeLessThanOrEqual(port,65535)} = 1502
            end
            obj.Host = host;
            obj.Port = port;
            obj.Tank = TankPLC;
        end

        function start(obj)
            if obj.Running, return; end
            assert(exist('tcpserver', 'file') ~= 0, ...
                'Install Instrument Control Toolbox to run the network server.');
            obj.Tank = TankPLC;
            obj.Tank.advance(0);
            obj.Clock = tic;
            obj.LastUpdate = 0;
            obj.Socket = tcpserver(obj.Host, obj.Port, ...
                'ConnectionChangedFcn', @(src,~) obj.connectionChanged(src));
            obj.Running = true;
            configureCallback(obj.Socket, 'byte', 1, @(src,~) obj.receive(src));
        end

        function tick(obj)
            if ~obj.Running, return; end
            elapsed = toc(obj.Clock);
            obj.Tank.advance(elapsed - obj.LastUpdate);
            obj.LastUpdate = elapsed;
        end

        function state = snapshot(obj)
            state = struct('Running', obj.Running, 'Host', obj.Host, ...
                'Port', obj.Port, 'Connected', false, 'ClientAddress', "", ...
                'Level', obj.Tank.Level, 'Target', obj.Tank.Target, ...
                'Enabled', obj.Tank.Enabled, 'Pump', obj.Tank.Pump, ...
                'Blocked', obj.Tank.Blocked);
            if obj.Running
                state.Connected = obj.Socket.Connected;
                if state.Connected
                    state.ClientAddress = string(obj.Socket.ClientAddress);
                end
            end
        end

        function stop(obj)
            obj.Running = false;
            if ~isempty(obj.Socket)
                configureCallback(obj.Socket, 'off');
                obj.Socket.ConnectionChangedFcn = [];
                delete(obj.Socket);
                obj.Socket = [];
            end
        end

        function delete(obj)
            obj.stop();
        end
    end
    methods (Access = private)
        function connectionChanged(obj, src)
            obj.Tank.resetConnection();
            if obj.Running
                configureCallback(src, 'byte', 1, @(source,~) obj.receive(source));
            end
        end

        function receive(obj, src)
            if ~obj.Running, return; end
            count = src.NumBytesAvailable;
            % A queued callback can run after an earlier one drained data.
            if count == 0, return; end
            obj.tick();
            bytes = read(src, count, 'uint8');
            wasBlocked = obj.Tank.Blocked;
            response = obj.Tank.receive(bytes);
            if ~isempty(response), write(src, response, 'uint8'); end
            if obj.Tank.Blocked && ~wasBlocked
                % Keep transport notifications active for reconnect events.
                warning('TankPLC:InvalidHeader', 'Invalid MBAP header; reconnect the client.');
            end
        end
    end
end
