function filename = export_register_map(filename)
%EXPORT_REGISTER_MAP Save named registers for Modbus Explorer's Import.
arguments
    filename (1,1) string = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'config', 'tank_registers.mat')
end
ModbusRegisterTable = table( ...
    ["WaterLevel_pct"; "TargetLevel_pct"; "ControllerEnabled"; "PumpRunning"], ...
    (1:4)', repmat("Holding Register",4,1), repmat("uint16",4,1), ones(4,1), ...
    'VariableNames', {'Name','Address','RegisterType','Precision','ServerId'});
folder = fileparts(filename);
if strlength(folder) > 0 && ~isfolder(folder), mkdir(folder); end
save(filename, 'ModbusRegisterTable');
fprintf('Modbus Explorer register map: %s\n', filename);
end
