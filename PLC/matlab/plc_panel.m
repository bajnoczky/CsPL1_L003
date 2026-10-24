function fig = plc_panel(visible)
%PLC_PANEL Nonblocking server controls and local tank display.
% Process commands (target and enable) remain in Modbus Explorer.
arguments
    visible (1,1) string {mustBeMember(visible,["on","off"])} = "on"
end
server = [];
fig = uifigure('Name', 'Virtual OT Lab | Tank PLC', ...
    'Position', [180, 140, 820, 590], 'Visible', visible, ...
    'Color', [0.96, 0.97, 0.98], 'CloseRequestFcn', @closePanel);
if isprop(fig, 'Theme'), fig.Theme = 'light'; end
layout = uigridlayout(fig, [6, 1], 'RowHeight', {40, 115, 30, '1x', 32, 30}, ...
    'Padding', [20, 16, 20, 16], 'RowSpacing', 10);
uilabel(layout, 'Text', 'VIRTUAL OT LAB  /  WATER TANK', ...
    'FontSize', 22, 'FontWeight', 'bold', 'FontColor', [0.10, 0.20, 0.29]);
settings = uipanel(layout, 'Title', 'PLC server', 'BackgroundColor', [1, 1, 1]);
grid = uigridlayout(settings, [2, 4], 'RowHeight', {24, 34}, ...
    'ColumnWidth', {'1x', 100, 110, 110}, 'Padding', [12, 8, 12, 8]);
uilabel(grid, 'Text', 'Bind IP address');
uilabel(grid, 'Text', 'TCP port');
uilabel(grid, 'Text', 'Unit ID: 1');
uilabel(grid, 'Text', '');
host = uieditfield(grid, 'text', 'Value', '127.0.0.1', 'Tag', 'Host');
port = uieditfield(grid, 'numeric', 'Value', 1502, 'Limits', [1, 65535], ...
    'RoundFractionalValues', 'on', 'Tag', 'Port');
startButton = uibutton(grid, 'Text', 'Start server', 'Tag', 'Start', ...
    'ButtonPushedFcn', @startServer);
stopButton = uibutton(grid, 'Text', 'Stop server', 'Tag', 'Stop', ...
    'Enable', 'off', 'ButtonPushedFcn', @stopServer);
status = uilabel(layout, 'Text', 'Stopped | No client connected', ...
    'Tag', 'Status', 'FontWeight', 'bold');
body = uigridlayout(layout, [1, 2], 'ColumnWidth', {'1x', 240}, ...
    'Padding', [0, 0, 0, 0]);
axes = uiaxes(body, 'Tag', 'TankAxes');
axes.XLim = [0, 1]; axes.YLim = [0, 100];
axes.XTick = []; axes.YTick = 0:20:100;
axes.YLabel.String = 'Water level (%)';
axes.Title.String = 'Tank level';
axes.Box = 'off'; axes.Toolbar.Visible = 'off';
disableDefaultInteractivity(axes);
hold(axes, 'on');
water = patch(axes, [0.18, 0.82, 0.82, 0.18], [0, 0, 30, 30], ...
    [0.17, 0.57, 0.82], 'EdgeColor', 'none', 'Tag', 'Water');
plot(axes, [0.18, 0.18, 0.82, 0.82], [100, 0, 0, 100], ...
    'Color', [0.2, 0.3, 0.4], 'LineWidth', 2);
targetLine = plot(axes, [0.12, 0.88], [60, 60], '--', ...
    'Color', [0.75, 0.35, 0.08], 'LineWidth', 1.5, 'Tag', 'TargetLine');
details = uigridlayout(body, [5, 1], 'RowHeight', {55, 35, 35, 35, '1x'});
levelText = uilabel(details, 'Text', '30%', 'Tag', 'Level', ...
    'FontSize', 38, 'FontWeight', 'bold', 'FontColor', [0.10, 0.36, 0.55]);
targetText = uilabel(details, 'Text', 'Target: 60%', 'Tag', 'Target', 'FontSize', 16);
enabledText = uilabel(details, 'Text', 'Controller: stopped', 'Tag', 'Controller');
pumpText = uilabel(details, 'Text', 'Pump: stopped', 'Tag', 'Pump');
uilabel(details, 'Text', sprintf('Dashed line = target\nStart resets the tank to 30%%.'), ...
    'WordWrap', 'on', 'FontColor', [0.35, 0.40, 0.45]);
uilabel(layout, 'Text', 'Change target and enable in Modbus Explorer. One client at a time.', ...
    'WordWrap', 'on');
message = uilabel(layout, 'Text', 'Ready. Start the server, then connect Modbus Explorer.', ...
    'Tag', 'Message', 'WordWrap', 'on', 'FontColor', [0.35, 0.40, 0.45]);
refreshTimer = timer('Name', 'VirtualOTLab panel refresh', 'ExecutionMode', 'fixedSpacing', ...
    'Period', 0.1, 'BusyMode', 'drop', 'TimerFcn', @refresh);
fig.UserData = struct('Timer', refreshTimer);
start(refreshTimer);

    function startServer(~, ~)
        try
            if ~isempty(server), delete(server); end
            server = TankServer(string(host.Value), port.Value);
            server.start();
            host.Enable = 'off'; port.Enable = 'off';
            startButton.Enable = 'off'; stopButton.Enable = 'on';
            message.Text = sprintf('Listening on %s:%d. Open Modbus Explorer to connect.', host.Value, port.Value);
            refresh([], []);
        catch error
            if ~isempty(server), delete(server); server = []; end
            message.Text = ['Could not start: ', error.message];
        end
    end

    function stopServer(~, ~)
        if ~isempty(server), server.stop(); end
        host.Enable = 'on'; port.Enable = 'on';
        startButton.Enable = 'on'; stopButton.Enable = 'off';
        status.Text = 'Stopped | No client connected';
        enabledText.Text = 'Controller: stopped';
        pumpText.Text = 'Pump: stopped';
        message.Text = 'Server stopped. Reconnect Explorer after restarting.';
    end

    function refresh(~, ~)
        if isempty(server) || ~server.Running, return; end
        try
            server.tick();
            state = server.snapshot();
            water.YData = [0, 0, state.Level, state.Level];
            targetLine.YData = [state.Target, state.Target];
            levelText.Text = sprintf('%.0f%%', state.Level);
            targetText.Text = sprintf('Target: %d%%', state.Target);
            if state.Enabled, enabledText.Text = 'Controller: enabled';
            else, enabledText.Text = 'Controller: disabled'; end
            if state.Pump, pumpText.Text = 'Pump: running';
            else, pumpText.Text = 'Pump: off'; end
            if state.Blocked
                status.Text = 'Running | Invalid request - reconnect client';
            elseif state.Connected
                status.Text = sprintf('Running | Client: %s', state.ClientAddress);
            else
                status.Text = 'Running | Waiting for a client';
            end
        catch error
            stopServer([], []);
            message.Text = ['Server stopped: ', error.message];
        end
    end

    function closePanel(~, ~)
        stop(refreshTimer);
        delete(refreshTimer);
        if ~isempty(server), delete(server); end
        delete(fig);
    end
end
