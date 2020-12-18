classdef KamelonControlApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainFrame                      matlab.ui.Figure
        SerialportselectDropDownLabel  matlab.ui.control.Label
        SerialPortSelect               matlab.ui.control.DropDown
        BaudrateEditFieldLabel         matlab.ui.control.Label
        Baudrate                       matlab.ui.control.NumericEditField
        Connect                        matlab.ui.control.Button
        CommandDropDownLabel           matlab.ui.control.Label
        CommandSelect                  matlab.ui.control.DropDown
        ValuesEditFieldLabel           matlab.ui.control.Label
        Values                         matlab.ui.control.EditField
        TextEditFieldLabel             matlab.ui.control.Label
        Text                           matlab.ui.control.EditField
        CommandType                    matlab.ui.container.ButtonGroup
        SetButton                      matlab.ui.control.RadioButton
        GetButton                      matlab.ui.control.RadioButton
        SendCommand                    matlab.ui.control.Button
        ReadvaluesEditFieldLabel       matlab.ui.control.Label
        ReadValues                     matlab.ui.control.EditField
        Graph                          matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        sp % Serial port
        plotGraph % plot
        tim % Timer for graph
    end
    
    methods (Access = private)
        
        function timFcn(app, ~, ~)
            %Odczytanie danych z MCU
            randNum = randi(pow2(12));         
            cmd = ":ADC?";                      
            write(app.sp, cmd, "string");
            write(app.sp, 13, "uint8");
            write(app.sp, 10, "uint8");
            read(app.sp, strlength(cmd) + 4, "string")
            read(app.sp, 2, "uint8");
            response = read(app.sp, 8, "string");
            response = response.extractBefore(";");           
            app.ReadValues.Value = response;                       
            randNum = hex2dec(response);            
            %Dodanie danych do wykresu
            yData = app.plotGraph.YData;
            yData = circshift(yData, 1);
            yData(1) = randNum;
            app.plotGraph.YData = yData;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
          ports = serialportlist;
          % TODO Sprawdzenie czy sa dostepne porty przed ustawieniem
          % kontrolki
          app.SerialPortSelect.Items = ports;
          
          app.Graph.XLim = [1 600];
          app.Graph.XDir = 'reverse';
         % app.Graph.XLabel = "Time [ms]";
          app.Graph.YLim = [0 pow2(12)];
         % app.Graph.YLabel = "Value";
          
          app.plotGraph = plot(app.Graph, 0:600, zeros(1, 601));
          
          app.tim = timer('ExecutionMode', 'fixedRate',"Period", 0.1, "BusyMode","queue","TimerFcn",@app.timFcn);
        end

        % Button pushed function: Connect
        function ConnectButtonPushed(app, event)
          if app.Connect.Text == "Connect"
              app.sp = serialport(app.SerialPortSelect.Value, app.Baudrate.Value, "Timeout", 0.05);
              app.Connect.Text = "Disconnect";              
              start(app.tim);
          else
              delete(app.sp);
              app.Connect.Text = "Connect";
              stop(app.tim);
          end
        end

        % Button pushed function: SendCommand
        function SendCommandButtonPushed(app, event)
            % Przygotowanie komend
          cmd = strcat(":", app.CommandSelect.Value);
          cmdValue = app.Values.Value;
          cmdText = app.Text.Value;
          if app.SetButton.Value
              cmdType = "=";
          cmd = strcat(cmd, cmdType, cmdValue);
           if app.CommandSelect.Value == "LCD"
               cmd = strcat(cmd, cmdText);
           end
          write(app.sp, cmd, "string");
          write(app.sp, 13, "uint8");
          write(app.sp, 10, "uint8");
          response = read(app.sp, strlength(cmd) + 7, "string")
          app.ReadValues.Value = response;
          else
            cmdType = "?";
            cmd = strcat(cmd, cmdType);
            write(app.sp, cmd, "string");
            write(app.sp, 13, "uint8");
            write(app.sp, 10, "uint8");
            response = read(app.sp, strlength(cmd) + 4, "string")
            read(app.sp, 2, "uint8");

            response = read(app.sp, 16, "string");
            app.ReadValues.Value = response;
          end
        end

        % Close request function: MainFrame
        function MainFrameCloseRequest(app, event)
            stop(app.tim);
            delete(app.tim);
            delete(app.sp);
            delete(app);
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MainFrame and hide until all components are created
            app.MainFrame = uifigure('Visible', 'off');
            app.MainFrame.Position = [100 100 600 335];
            app.MainFrame.Name = 'MATLAB App';
            app.MainFrame.CloseRequestFcn = createCallbackFcn(app, @MainFrameCloseRequest, true);

            % Create SerialportselectDropDownLabel
            app.SerialportselectDropDownLabel = uilabel(app.MainFrame);
            app.SerialportselectDropDownLabel.HorizontalAlignment = 'right';
            app.SerialportselectDropDownLabel.Position = [22 299 95 22];
            app.SerialportselectDropDownLabel.Text = 'Serial port select';

            % Create SerialPortSelect
            app.SerialPortSelect = uidropdown(app.MainFrame);
            app.SerialPortSelect.Items = {'Option 1', 'Option 2'};
            app.SerialPortSelect.Position = [132 299 112 22];

            % Create BaudrateEditFieldLabel
            app.BaudrateEditFieldLabel = uilabel(app.MainFrame);
            app.BaudrateEditFieldLabel.HorizontalAlignment = 'right';
            app.BaudrateEditFieldLabel.Position = [23 263 58 22];
            app.BaudrateEditFieldLabel.Text = 'Baudrate:';

            % Create Baudrate
            app.Baudrate = uieditfield(app.MainFrame, 'numeric');
            app.Baudrate.ValueDisplayFormat = '%.0f';
            app.Baudrate.HorizontalAlignment = 'center';
            app.Baudrate.Position = [96 263 149 22];
            app.Baudrate.Value = 115200;

            % Create Connect
            app.Connect = uibutton(app.MainFrame, 'push');
            app.Connect.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.Connect.Position = [23 234 222 22];
            app.Connect.Text = 'Connect';

            % Create CommandDropDownLabel
            app.CommandDropDownLabel = uilabel(app.MainFrame);
            app.CommandDropDownLabel.HorizontalAlignment = 'right';
            app.CommandDropDownLabel.Position = [23 200 64 22];
            app.CommandDropDownLabel.Text = 'Command:';

            % Create CommandSelect
            app.CommandSelect = uidropdown(app.MainFrame);
            app.CommandSelect.Items = {'RST', 'LED', 'RGB', 'LCD', 'SEG', 'JOY', 'ADC'};
            app.CommandSelect.Position = [102 200 143 22];
            app.CommandSelect.Value = 'RST';

            % Create ValuesEditFieldLabel
            app.ValuesEditFieldLabel = uilabel(app.MainFrame);
            app.ValuesEditFieldLabel.HorizontalAlignment = 'right';
            app.ValuesEditFieldLabel.Position = [44 167 44 22];
            app.ValuesEditFieldLabel.Text = 'Values:';

            % Create Values
            app.Values = uieditfield(app.MainFrame, 'text');
            app.Values.Position = [103 167 142 22];
            app.Values.Value = '0x00';

            % Create TextEditFieldLabel
            app.TextEditFieldLabel = uilabel(app.MainFrame);
            app.TextEditFieldLabel.HorizontalAlignment = 'right';
            app.TextEditFieldLabel.Position = [60 138 31 22];
            app.TextEditFieldLabel.Text = 'Text:';

            % Create Text
            app.Text = uieditfield(app.MainFrame, 'text');
            app.Text.Position = [106 138 138 22];
            app.Text.Value = 'Demo';

            % Create CommandType
            app.CommandType = uibuttongroup(app.MainFrame);
            app.CommandType.Title = 'Command type:';
            app.CommandType.Position = [22 84 222 46];

            % Create SetButton
            app.SetButton = uiradiobutton(app.CommandType);
            app.SetButton.Text = 'Set';
            app.SetButton.Position = [27 0 58 22];
            app.SetButton.Value = true;

            % Create GetButton
            app.GetButton = uiradiobutton(app.CommandType);
            app.GetButton.Text = 'Get';
            app.GetButton.Position = [120 0 65 22];

            % Create SendCommand
            app.SendCommand = uibutton(app.MainFrame, 'push');
            app.SendCommand.ButtonPushedFcn = createCallbackFcn(app, @SendCommandButtonPushed, true);
            app.SendCommand.Position = [23 50 222 22];
            app.SendCommand.Text = 'Send command';

            % Create ReadvaluesEditFieldLabel
            app.ReadvaluesEditFieldLabel = uilabel(app.MainFrame);
            app.ReadvaluesEditFieldLabel.HorizontalAlignment = 'right';
            app.ReadvaluesEditFieldLabel.Position = [22 14 75 22];
            app.ReadvaluesEditFieldLabel.Text = 'Read values:';

            % Create ReadValues
            app.ReadValues = uieditfield(app.MainFrame, 'text');
            app.ReadValues.Position = [112 14 132 22];

            % Create Graph
            app.Graph = uiaxes(app.MainFrame);
            title(app.Graph, 'ADC value')
            xlabel(app.Graph, 'Sample')
            ylabel(app.Graph, 'Value')
            zlabel(app.Graph, 'Z')
            app.Graph.Position = [258 14 328 307];

            % Show the figure after all components are created
            app.MainFrame.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = KamelonControlApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MainFrame)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MainFrame)
        end
    end
end