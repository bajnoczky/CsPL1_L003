classdef TankPLC < handle
    %TANKPLC Toolbox-independent tank, controller, and Modbus/TCP subset.
    properties (SetAccess = private)
        Level = 30
        Target = 60
        Enabled = true
        Pump = false
        Blocked = false
    end
    properties (Access = private)
        Buffer = uint8([])
    end
    methods
        function advance(obj, seconds)
            % Pump supplies 8 points/s; the outlet drains 2 points/s.
            obj.Level = min(100, max(0, obj.Level + (8 * double(obj.Pump) - 2) * seconds));
            obj.control();
        end

        function resetConnection(obj)
            obj.Buffer = uint8([]);
            obj.Blocked = false;
        end

        function responses = receive(obj, bytes)
            responses = uint8([]);
            if obj.Blocked, return; end
            obj.Buffer = [obj.Buffer, reshape(uint8(bytes), 1, [])];
            % TCP can deliver partial frames or several frames at once.
            while numel(obj.Buffer) >= 7
                bodyLength = word(obj.Buffer(5:6));
                if word(obj.Buffer(3:4)) ~= 0 || bodyLength < 2 || bodyLength > 254
                    obj.Blocked = true; % Cannot trust the frame boundary.
                    obj.Buffer = uint8([]);
                    return
                end
                frameLength = 6 + bodyLength;
                if numel(obj.Buffer) < frameLength, return; end
                request = obj.Buffer(1:frameLength);
                obj.Buffer(1:frameLength) = [];
                if request(7) ~= 1, continue; end
                reply = obj.processPdu(request(8:end));
                responses = [responses, request(1:4), packWord(1 + numel(reply)), uint8(1), reply]; %#ok<AGROW>
            end
        end
    end
    methods (Access = private)
        function control(obj)
            if ~obj.Enabled || obj.Level >= obj.Target
                obj.Pump = false;
            elseif obj.Level <= max(0, obj.Target - 3)
                obj.Pump = true;
            end
        end

        function reply = processPdu(obj, pdu)
            fc = double(pdu(1));
            reply = uint8([bitor(fc, 128), 3]); % Invalid value/length.
            switch fc
                case 3
                    if numel(pdu) ~= 5, return; end
                    first = word(pdu(2:3)) + 1;
                    count = word(pdu(4:5));
                    if count < 1 || count > 125, return; end
                    if first > 4 || first + count - 1 > 4
                        reply(2) = 2;
                        return
                    end
                    registers = [round(obj.Level), obj.Target, double(obj.Enabled), double(obj.Pump)];
                    reply = uint8([3, 2 * count]);
                    for value = registers(first:first + count - 1)
                        reply = [reply, packWord(value)]; %#ok<AGROW>
                    end
                case {6, 16}
                    if fc == 6
                        if numel(pdu) ~= 5, return; end
                        first = word(pdu(2:3)) + 1;
                        values = word(pdu(4:5));
                    else
                        if numel(pdu) < 6, return; end
                        first = word(pdu(2:3)) + 1;
                        count = word(pdu(4:5));
                        if count < 1 || count > 123 || double(pdu(6)) ~= 2 * count ...
                                || numel(pdu) ~= 6 + 2 * count
                            return
                        end
                        values = zeros(1, count);
                        for k = 1:count
                            values(k) = word(pdu(5 + 2*k:6 + 2*k));
                        end
                    end
                    addresses = first:first + numel(values) - 1;
                    if any(addresses < 2 | addresses > 3)
                        reply(2) = 2; % Level and pump state are read-only.
                        return
                    end
                    if any(values(addresses == 2) > 100) || any(values(addresses == 3) > 1)
                        return
                    end
                    % Validate all values before changing any register.
                    for k = 1:numel(values)
                        if addresses(k) == 2, obj.Target = values(k); end
                        if addresses(k) == 3, obj.Enabled = logical(values(k)); end
                    end
                    obj.control();
                    reply = pdu(1:5); % Echo value (06) or quantity (16).
                otherwise
                    reply = uint8([bitor(fc, 128), 1]);
            end
        end
    end
end

function value = word(bytes)
value = 256 * double(bytes(1)) + double(bytes(2));
end

function bytes = packWord(value)
bytes = uint8([floor(double(value) / 256), mod(double(value), 256)]);
end
