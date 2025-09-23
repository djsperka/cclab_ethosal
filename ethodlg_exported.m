classdef ethodlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        OverridesPanel           matlab.ui.container.Panel
        GridLayout3              matlab.ui.container.GridLayout
        RespTimesEditField       matlab.ui.control.NumericEditField
        RespTimesEditFieldLabel  matlab.ui.control.Label
        RespTimeOverride         matlab.ui.control.CheckBox
        TestTimesEditField       matlab.ui.control.NumericEditField
        TestTimesEditFieldLabel  matlab.ui.control.Label
        TestTimeOverride         matlab.ui.control.CheckBox
        GapTimesEditField        matlab.ui.control.NumericEditField
        GapTimesEditFieldLabel   matlab.ui.control.Label
        GapTimeOverride          matlab.ui.control.CheckBox
        SampTimesEditField       matlab.ui.control.NumericEditField
        SampTimesEditFieldLabel  matlab.ui.control.Label
        SampTimeOverride         matlab.ui.control.CheckBox
        Stim2YEditField          matlab.ui.control.NumericEditField
        Stim2XEditField          matlab.ui.control.NumericEditField
        Stim2XYEditFieldLabel    matlab.ui.control.Label
        Stim2XYOverride          matlab.ui.control.CheckBox
        Stim1YEditField          matlab.ui.control.NumericEditField
        Stim1XEditField          matlab.ui.control.NumericEditField
        Stim1XYEditFieldLabel    matlab.ui.control.Label
        Stim1XYOverride          matlab.ui.control.CheckBox
        SelectImagesButton       matlab.ui.control.Button
        ImagesetNameLabel        matlab.ui.control.Label
        ImagesetLabel            matlab.ui.control.Label
        BlockSelectedLabel       matlab.ui.control.Label
        BlockLabel               matlab.ui.control.Label
        TrialsFileLabel          matlab.ui.control.Label
        TrialsLabel              matlab.ui.control.Label
        ScrWHmmEditFieldLabel    matlab.ui.control.Label
        ScrDistmmEditFieldLabel  matlab.ui.control.Label
        LocationLabel            matlab.ui.control.Label
        ExitButton               matlab.ui.control.Button
        TesttypeDropDownLabel    matlab.ui.control.Label
        OptionsPanel             matlab.ui.container.Panel
        GridLayout2              matlab.ui.container.GridLayout
        AudFeedbackCheckBox      matlab.ui.control.CheckBox
        UseboothkbdCheckBox      matlab.ui.control.CheckBox
        ShowImageNamesCheckBox   matlab.ui.control.CheckBox
        ThresholdCheckBox        matlab.ui.control.CheckBox
        RunButton                matlab.ui.control.Button
        GoalDirectedDropDown     matlab.ui.control.DropDown
        GoalDirectedCheck        matlab.ui.control.CheckBox
        SelectBlockButton        matlab.ui.control.Button
        SelectTrialsButton       matlab.ui.control.Button
        ScrWHmmEditField         matlab.ui.control.EditField
        ScrDistmmEditField       matlab.ui.control.EditField
        LocationDropDown         matlab.ui.control.DropDown
        TesttypeDropDown         matlab.ui.control.DropDown
        SubjectIDEditField       matlab.ui.control.EditField
        SubjectIDEditFieldLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        pathDataRoot % root folder for input/output data
        pathImgRoot % root folder for imageset
        isFileSelected % set to true when trial/blocks file is chosen
        filePath % path of trials/blocks file
        fileName % basename of trials/blocks file
        fileNBlocks % number of blocks in trials file (0 if bare trials, no blocks)
        fileBlockIndex % which block in file, or 0 if none selected
        isImagesetSelected % set to true when images selected
        imagesetName % Name of imageset to use
        imagesetParamsFunc % Paramsfunc to use when loading imageset
        Y % input file loaded. Will contain blocks or trials et al.
        isTrialsSelected % file is selected, and a block also if needed
        isBlocksetSelected % Description
    end
    
    methods (Access = private)
        
        function updateFileBlocks(app)
            %Update GUI elements related to the filename and block
            %selected, including BlockSelectedLabel, TrialsFileLabel, 
            % GoalDirectedCheck, and GoalDirectedDropDown
            if app.isFileSelected
                app.TrialsFileLabel.Text = app.fileName;
                if app.fileNBlocks > 0
                    if app.fileBlockIndex <= app.fileNBlocks
                        if app.isBlocksetSelected
                            app.BlockSelectedLabel.Text = sprintf('%d/%d (multiple blocks will run)', app.fileBlockIndex, app.fileNBlocks);
                        else
                            app.BlockSelectedLabel.Text = sprintf('%d/%d', app.fileBlockIndex, app.fileNBlocks);
                        end
                    else
                        app.BlockSelectedLabel.Text = 'Not selected';
                    end
                else
                    app.BlockSelectedLabel.Text = 'N/A';
                end
            else
                app.TrialsFileLabel.Text = 'Not selected';
                app.BlockSelectedLabel.Text = 'N/A';
            end

            if app.isTrialsSelected
                app.GoalDirectedCheck.Enable = true;
                app.GoalDirectedDropDown.Enable = true;
            else
                app.GoalDirectedCheck.Value = false;
                app.GoalDirectedCheck.Enable = true;
                app.GoalDirectedDropDown.Enable = true;
            end
            if app.isImagesetSelected
                app.ImagesetNameLabel.Text = sprintf('%s [%s]', app.imagesetName, app.imagesetParamsFunc);
            else
                app.ImagesetNameLabel.Text = 'None selected';
            end
        end
        
        function trials = getSelectedTrials(app)
            if app.isFileSelected
                if app.fileNBlocks > 0
                    if app.fileBlockIndex > 0 && app.fileBlockIndex <= app.fileNBlocks
                        trials = app.Y.blocks{app.fileBlockIndex};
                    else
                        me = MException('ethodlg:badblockindex', 'Must select block number to use.');
                        throw(me);
                    end
                else
                    trials = app.Y.trials;
                end

                % Apply overrides
                    
            else
                me = MException('ethodlg:nofile', 'Input blocks/trials file is not selected.');
                throw(me);
            end
        end
        
        function ttype = getTestType(app)
            ttype = app.TesttypeDropDown.Value;
        end
        
        function isReady = checkRunButton(app)
            isReady = ~isempty(app.SubjectIDEditField.Value) && app.isImagesetSelected && app.isTrialsSelected;
            app.RunButton.Enable = isReady;
        end
        
        function selectBlockNumberDialog(app)
            %Select a block number from the currently selected input file.

            % make a cell array with the numeric values 1:nBlocks, and
            % the last value is 'None Selected'
            if app.isBlocksetSelected
                C = {app.Y.blockset.label};
                pstring = 'Select starting block';
            else
                C=[cellfun(@(x) sprintf('%d',x), num2cell(1:app.fileNBlocks),UniformOutput=false),{'None Selected'}];
                pstring = 'Select a block';
            end
            if app.isFileSelected && app.fileNBlocks>0
                if app.fileBlockIndex < app.fileNBlocks && app.fileBlockIndex > 0
                    initialValue = app.fileBlockIndex;
                else
                    initialValue = length(C);
                end
            else
                initialValue = length(C);
            end
            [indexSelected,tf]=listdlg(PromptString=pstring,ListString=C,SelectionMode='single',ListSize=[150, 25*length(C)],InitialValue=initialValue);
            if tf
                app.fileBlockIndex = indexSelected;
                if indexSelected <= app.fileNBlocks
                    app.isTrialsSelected = true;
                else
                    app.isTrialsSelected = false;
                end
            end
        end
        
        function enableDialog(app, enableFlag)
            % enableFlag is either true (Enable=on) or false (enable=off).
            components = [app.RunButton, app.ExitButton, app.OptionsPanel, app.OverridesPanel];
            if enableFlag
                flag = 'On';
            else
                flag = 'Off';
            end 
            set(components, 'Enable', flag);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, ethDataRoot, ethImgRoot)

            app.pathDataRoot = ethDataRoot;
            app.pathImgRoot = ethImgRoot;
            app.isFileSelected = false;
            app.isBlocksetSelected = false;
            app.isImagesetSelected = false;
            app.imagesetName = '';
            app.imagesetParamsFunc = '';
            app.fileBlockIndex = -1;
            app.fileNBlocks = -1;
            app.Y = [];
            app.isTrialsSelected = false;
            app.RunButton.Enable = false;

            app.Stim1XEditField.Enable = false;
            app.Stim1YEditField.Enable = false;
            app.Stim2XEditField.Enable = false;
            app.Stim2YEditField.Enable = false;
            app.SampTimesEditField.Enable = false;
            app.GapTimesEditField.Enable = false;
            app.TestTimesEditField.Enable = false;
            app.RespTimesEditField.Enable = false;

            updateFileBlocks(app);

        end

        % Button pushed function: SelectTrialsButton
        function LoadTrialsPushed(app, event)
            switch getTestType(app)
                case 'Image'
                    ttype = 'mimg';
                case 'Rotate'
                    ttype= 'rimg';
                case 'Gabor'
                    ttype = 'gab';
                case 'Flip'
                    ttype = 'rimg';
            end

            if app.ThresholdCheckBox.Value
                etype = 'thr';
            else
                etype = 'exp';
            end
            pathInitial = fullfile(app.pathDataRoot, 'input');
            filterFile = [ttype,'_',etype,'_*.mat'];
            [fileSelected,pathSelected] = uigetfile(filterFile,'Select trials file', pathInitial);  %open a mat file

            if ischar(fileSelected)    
                % check input file for 'blocks' - if so, enable block
                % selection.
                app.isFileSelected = true;
                app.fileName = fileSelected;
                app.filePath = pathSelected;
                app.Y = load(fullfile(pathSelected, fileSelected));
                
                if any(strcmp('blocks', fieldnames(app.Y)))
                    app.fileNBlocks = length(app.Y.blocks);
                    app.selectBlockNumberDialog();
                    app.isBlocksetSelected = false;
                elseif any(strcmp('trials', fieldnames(app.Y)))
                    app.fileNBlocks = 0;
                    app.fileBlockIndex = 0;
                    app.isTrialsSelected = true;
                    app.isBlocksetSelected = false;
                elseif any(strcmp('blockset', fieldnames(app.Y)))
                    app.fileNBlocks = length(app.Y.blockset);
                    app.fileBlockIndex = 0;
                    app.isTrialsSelected = true;
                    app.isBlocksetSelected = true;
                    app.selectBlockNumberDialog();
                else
                    app.isBlocksetSelected = false;
                    app.isFileSelected = false;
                    app.fileName = '';
                    app.filePath = '';
                    me = MException('ethodlg:bad_input', 'Input mat file does not have blocks or trials.');
                    throw(me);
                end

                % See if imageset info is contained

                if any(contains(fieldnames(app.Y), 'imagesetName')) && any(contains(fieldnames(app.Y), 'imagesetParamsFunc'))
                    app.isImagesetSelected = true;
                    app.imagesetName = app.Y.imagesetName;
                    app.imagesetParamsFunc = app.Y.imagesetParamsFunc;
                end

                % see if we can populate override fields
                if any(contains(fieldnames(app.Y), 'genFuncParserResults'))
                    r=app.Y.genFuncParserResults;
                    app.SampTimesEditField.Value = r.SampTime;
                    app.GapTimesEditField.Value = r.GapTime;
                    app.TestTimesEditField.Value = r.TestTime;
                    app.RespTimesEditField.Value = r.RespTime;
                end
                    
            end
            updateFileBlocks(app);
            checkRunButton(app);
            drawnow;
        end

        % Button pushed function: SelectImagesButton
        function SelectImagesButtonPushed(app, event)
            [pfuncSelected,pathSelected] = uigetfile('*.m','Select imageset loader', app.pathImgRoot);  %open a mat file

            if ischar(pfuncSelected)    
                [~,app.imagesetParamsFunc,~] = fileparts(pfuncSelected);
                c=split(strip(pathSelected,filesep),filesep);
                app.imagesetName = c{end};
                app.isImagesetSelected = true;
            end
            app.updateFileBlocks();
            app.checkRunButton();
            drawnow;
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)


            % Now try to run the thing
            try
                imagesetPath = fullfile(app.pathImgRoot,app.imagesetName);
                fprintf('Load images from %s using func [%s]\n', imagesetPath, app.imagesetParamsFunc);

                if app.ShowImageNamesCheckBox.Value
                    img = imageset(imagesetPath, app.imagesetParamsFunc, 'ShowName', true);
                else
                    img = imageset(imagesetPath, app.imagesetParamsFunc);
                end


                % The value from screen distance comes to us as a char array
                % 
                fprintf('Screen distance (ignored) %d\n', str2double(app.ScrDistmmEditField.Value));
                app.ScrWHmmEditField.Value
                atmp = eval(['[',app.ScrWHmmEditField.Value,']'])
                fprintf('Screen WH %dx%d (ignored)\n', atmp(1), atmp(2));

                % get trials, overrides if any. 
                % also set some arguments for etholog
                if ~app.isBlocksetSelected

                    % id is the basename of the output file in this case,
                    % including the input filename base and the block
                    % number.
                    [~, base, ~] = fileparts(app.fileName);
                    if app.fileNBlocks > 0
                        blok = sprintf('%s_blk%d', base, app.fileBlockIndex);
                    else
                        blok = sprintf('%s', base);
                    end
                    id = [char(datetime('now','Format','yyyy-MM-dd-HHmm')), '_', app.SubjectIDEditField.Value, '_', blok];

                    trials = app.getSelectedTrials();
                    if app.RespTimeOverride.Value
                        trials.RespTime(:) = app.RespTimesEditField.Value;
                    end
                    if app.SampTimeOverride.Value
                        trials.SampTime(:) = app.SampTimesEditField.Value;
                    end
                    if app.TestTimeOverride.Value
                        trials.TestTime(:) = app.TestTimesEditField.Value;
                    end
                    if app.GapTimeOverride.Value
                        trials.GapTime(:) = app.GapTimesEditField.Value;
                    end
                else

                    % id is just the subject ID - etholog will finalize the 
                    % filename with the date and time and folder.
                    id = app.SubjectIDEditField.Value;


                    trials = app.Y.blockset;
                    % If I were more clever, I wouldn't have this loop run
                    % all the time.            
                    for i=1:length(trials)
                        if app.RespTimeOverride.Value
                            trials(i).trials.RespTime(:) = app.RespTimesEditField.Value;
                        end
                        if app.SampTimeOverride.Value
                            trials(i).trials.SampTime(:) = app.SampTimesEditField.Value;
                        end
                        if app.TestTimeOverride.Value
                            trials(i).trials.TestTime(:) = app.TestTimesEditField.Value;
                        end
                        if app.GapTimeOverride.Value
                            trials(i).trials.GapTime(:) = app.GapTimesEditField.Value;
                        end
                    end
                end

                % Form arguments cell array
                args = {
                    id, 'Test', app.LocationDropDown.Value, ...
                    'Trials', trials, ...
                    'Threshold', app.ThresholdCheckBox.Value, ...
                    'Beep', app.AudFeedbackCheckBox.Value, ...
                    'ExperimentTestType', app.getTestType(), ... 
                    'StartBlock', app.fileBlockIndex, ...
                    'Images', img, ... 
                    'Inside', app.UseboothkbdCheckBox.Value
                    };

                if app.Stim1XYOverride.Value
                    args{end+1} = 'Stim1XY';
                    args{end+1} = [app.Stim1XEditField.Value, app.Stim1YEditField.Value];
                end

                if app.Stim2XYOverride.Value
                    args{end+1} = 'Stim2XY';
                    args{end+1} = [app.Stim2XEditField.Value, app.Stim2YEditField.Value];
                end

                % goal directed arg only if NOT a blockset. In a blockset,
                % there is a goaldirected field, the setting for each
                % block.
                if ~app.isBlocksetSelected && app.GoalDirectedCheck.Value
                    args{end+1} = 'GoalDirected';
                    args{end+1} = app.GoalDirectedDropDown.Value;
                end

                %run_ethologV2(id, 'Test', app.LocationDropDown.Value, 'Trials', app.getSelectedTrials(), 'Threshold', app.ThresholdCheckBox.Value, 'ExperimentTestType', app.getTestType(), 'Images', img, 'Inside', app.UseboothkbdCheckBox.Value);
                app.enableDialog(false);
                run_ethologV2(args{:});
                app.enableDialog(true);

            catch ME
                fprintf('Error running expt:\n%s\n%s\n', ME.message, ME.getReport());
            end

        end

        % Button pushed function: ExitButton
        function ExitButtonPushed(app, event)
            % shut down entire app
            delete(app);
        end

        % Value changed function: SubjectIDEditField
        function AnyValueChanged(app, event)
            % Check if we can run expt
            app.checkRunButton();
            drawnow;
        end

        % Button pushed function: SelectBlockButton
        function SelectBlockButtonPushed(app, event)
            app.selectBlockNumberDialog();
            app.updateFileBlocks();
            app.checkRunButton();
            drawnow;
        end

        % Value changed function: Stim1XYOverride
        function Stim1XYOverrideValueChanged(app, event)
            value = app.Stim1XYOverride.Value;
            app.Stim1XEditField.Enable = value;            
            app.Stim1YEditField.Enable = value;
        end

        % Value changed function: Stim2XYOverride
        function Stim2XYOverrideValueChanged(app, event)
            value = app.Stim2XYOverride.Value;
            app.Stim2XEditField.Enable = value;            
            app.Stim2YEditField.Enable = value;            
        end

        % Value changed function: SampTimeOverride
        function SampTimeOverrideValueChanged(app, event)
            value = app.SampTimeOverride.Value;
            app.SampTimesEditField.Enable = value;
        end

        % Value changed function: GapTimeOverride
        function GapTimeOverrideValueChanged(app, event)
            value = app.GapTimeOverride.Value;
            app.GapTimesEditField.Enable = value;
        end

        % Value changed function: TestTimeOverride
        function TestTimeOverrideValueChanged(app, event)
            value = app.TestTimeOverride.Value;
            app.TestTimesEditField.Enable = value;
        end

        % Value changed function: RespTimeOverride
        function RespTimeOverrideValueChanged(app, event)
            value = app.RespTimeOverride.Value;
            app.RespTimesEditField.Enable = value;
        end

        % Value changed function: ScrWHmmEditField
        function ScrWHValueChanged(app, event)
            value = app.ScrWHmmEditField.Value;
            try
                s = sprintf('aaatmp=%s', value);
                eval(s);
            catch ME
                msgText = getReport(ME);
                fprintf('Cannot evaluate WxH:\n%s\n', msgText);
                app.ScrWHmmEditField.Value = event.PreviousValue;
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 492 542];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'20x', '30x', '30x', '20x'};
            app.GridLayout.RowHeight = {24, 22, 24, 22, 22, 22, 22, 22, 23, '1x'};

            % Create SubjectIDEditFieldLabel
            app.SubjectIDEditFieldLabel = uilabel(app.GridLayout);
            app.SubjectIDEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectIDEditFieldLabel.Layout.Row = 1;
            app.SubjectIDEditFieldLabel.Layout.Column = 1;
            app.SubjectIDEditFieldLabel.Text = 'Subject ID';

            % Create SubjectIDEditField
            app.SubjectIDEditField = uieditfield(app.GridLayout, 'text');
            app.SubjectIDEditField.ValueChangedFcn = createCallbackFcn(app, @AnyValueChanged, true);
            app.SubjectIDEditField.Layout.Row = 1;
            app.SubjectIDEditField.Layout.Column = 2;

            % Create TesttypeDropDown
            app.TesttypeDropDown = uidropdown(app.GridLayout);
            app.TesttypeDropDown.Items = {'Image', 'Rotate', 'Gabor', 'Flip'};
            app.TesttypeDropDown.ItemsData = {'Image', 'Rotate', 'Gabor', 'Flip', 'ERR'};
            app.TesttypeDropDown.Layout.Row = 2;
            app.TesttypeDropDown.Layout.Column = 2;
            app.TesttypeDropDown.Value = 'Flip';

            % Create LocationDropDown
            app.LocationDropDown = uidropdown(app.GridLayout);
            app.LocationDropDown.Items = {'Booth (test)', 'Booth (subj)', 'Desk', 'Mangun-desk'};
            app.LocationDropDown.ItemsData = {'booth', 'no-test', 'desk', 'mangun-desk'};
            app.LocationDropDown.Layout.Row = 3;
            app.LocationDropDown.Layout.Column = 2;
            app.LocationDropDown.Value = 'booth';

            % Create ScrDistmmEditField
            app.ScrDistmmEditField = uieditfield(app.GridLayout, 'text');
            app.ScrDistmmEditField.InputType = 'digits';
            app.ScrDistmmEditField.Layout.Row = 4;
            app.ScrDistmmEditField.Layout.Column = 2;
            app.ScrDistmmEditField.Value = '920';

            % Create ScrWHmmEditField
            app.ScrWHmmEditField = uieditfield(app.GridLayout, 'text');
            app.ScrWHmmEditField.ValueChangedFcn = createCallbackFcn(app, @ScrWHValueChanged, true);
            app.ScrWHmmEditField.Layout.Row = 5;
            app.ScrWHmmEditField.Layout.Column = 2;
            app.ScrWHmmEditField.Value = '598,336';

            % Create SelectTrialsButton
            app.SelectTrialsButton = uibutton(app.GridLayout, 'push');
            app.SelectTrialsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadTrialsPushed, true);
            app.SelectTrialsButton.Layout.Row = 6;
            app.SelectTrialsButton.Layout.Column = 4;
            app.SelectTrialsButton.Text = 'Select Trials';

            % Create SelectBlockButton
            app.SelectBlockButton = uibutton(app.GridLayout, 'push');
            app.SelectBlockButton.ButtonPushedFcn = createCallbackFcn(app, @SelectBlockButtonPushed, true);
            app.SelectBlockButton.Layout.Row = 7;
            app.SelectBlockButton.Layout.Column = 4;
            app.SelectBlockButton.Text = 'Select Block';

            % Create GoalDirectedCheck
            app.GoalDirectedCheck = uicheckbox(app.GridLayout);
            app.GoalDirectedCheck.Text = 'Goal-directed cues';
            app.GoalDirectedCheck.Layout.Row = 8;
            app.GoalDirectedCheck.Layout.Column = 2;

            % Create GoalDirectedDropDown
            app.GoalDirectedDropDown = uidropdown(app.GridLayout);
            app.GoalDirectedDropDown.Items = {'None', 'Use existing', 'Stim1 (Left)', 'Stim2 (Right)'};
            app.GoalDirectedDropDown.ItemsData = {'none', 'existing', 'stim1', 'stim2'};
            app.GoalDirectedDropDown.Layout.Row = 8;
            app.GoalDirectedDropDown.Layout.Column = 3;
            app.GoalDirectedDropDown.Value = 'none';

            % Create RunButton
            app.RunButton = uibutton(app.GridLayout, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Layout.Row = 1;
            app.RunButton.Layout.Column = 4;
            app.RunButton.Text = 'Run';

            % Create OptionsPanel
            app.OptionsPanel = uipanel(app.GridLayout);
            app.OptionsPanel.Title = 'Options';
            app.OptionsPanel.Layout.Row = [1 5];
            app.OptionsPanel.Layout.Column = 3;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.OptionsPanel);
            app.GridLayout2.ColumnWidth = {'1x'};
            app.GridLayout2.RowHeight = {'fit', 'fit', 'fit', 'fit'};

            % Create ThresholdCheckBox
            app.ThresholdCheckBox = uicheckbox(app.GridLayout2);
            app.ThresholdCheckBox.Text = 'Threshold?';
            app.ThresholdCheckBox.Layout.Row = 1;
            app.ThresholdCheckBox.Layout.Column = 1;

            % Create ShowImageNamesCheckBox
            app.ShowImageNamesCheckBox = uicheckbox(app.GridLayout2);
            app.ShowImageNamesCheckBox.Text = 'Show Img Names';
            app.ShowImageNamesCheckBox.Layout.Row = 2;
            app.ShowImageNamesCheckBox.Layout.Column = 1;

            % Create UseboothkbdCheckBox
            app.UseboothkbdCheckBox = uicheckbox(app.GridLayout2);
            app.UseboothkbdCheckBox.Text = 'Use booth kbd';
            app.UseboothkbdCheckBox.Layout.Row = 3;
            app.UseboothkbdCheckBox.Layout.Column = 1;

            % Create AudFeedbackCheckBox
            app.AudFeedbackCheckBox = uicheckbox(app.GridLayout2);
            app.AudFeedbackCheckBox.Text = 'Aud Feedback';
            app.AudFeedbackCheckBox.Layout.Row = 4;
            app.AudFeedbackCheckBox.Layout.Column = 1;

            % Create TesttypeDropDownLabel
            app.TesttypeDropDownLabel = uilabel(app.GridLayout);
            app.TesttypeDropDownLabel.Layout.Row = 2;
            app.TesttypeDropDownLabel.Layout.Column = 1;
            app.TesttypeDropDownLabel.Text = 'Test type:';

            % Create ExitButton
            app.ExitButton = uibutton(app.GridLayout, 'push');
            app.ExitButton.ButtonPushedFcn = createCallbackFcn(app, @ExitButtonPushed, true);
            app.ExitButton.Layout.Row = 2;
            app.ExitButton.Layout.Column = 4;
            app.ExitButton.Text = 'Exit';

            % Create LocationLabel
            app.LocationLabel = uilabel(app.GridLayout);
            app.LocationLabel.Layout.Row = 3;
            app.LocationLabel.Layout.Column = 1;
            app.LocationLabel.Text = 'Location:';

            % Create ScrDistmmEditFieldLabel
            app.ScrDistmmEditFieldLabel = uilabel(app.GridLayout);
            app.ScrDistmmEditFieldLabel.Layout.Row = 4;
            app.ScrDistmmEditFieldLabel.Layout.Column = 1;
            app.ScrDistmmEditFieldLabel.Text = 'Scr Dist (mm)';

            % Create ScrWHmmEditFieldLabel
            app.ScrWHmmEditFieldLabel = uilabel(app.GridLayout);
            app.ScrWHmmEditFieldLabel.Layout.Row = 5;
            app.ScrWHmmEditFieldLabel.Layout.Column = 1;
            app.ScrWHmmEditFieldLabel.Text = 'Scr W,H (mm)';

            % Create TrialsLabel
            app.TrialsLabel = uilabel(app.GridLayout);
            app.TrialsLabel.Layout.Row = 6;
            app.TrialsLabel.Layout.Column = 1;
            app.TrialsLabel.Text = 'Trials:';

            % Create TrialsFileLabel
            app.TrialsFileLabel = uilabel(app.GridLayout);
            app.TrialsFileLabel.Layout.Row = 6;
            app.TrialsFileLabel.Layout.Column = [2 3];

            % Create BlockLabel
            app.BlockLabel = uilabel(app.GridLayout);
            app.BlockLabel.Layout.Row = 7;
            app.BlockLabel.Layout.Column = 1;
            app.BlockLabel.Text = 'Block:';

            % Create BlockSelectedLabel
            app.BlockSelectedLabel = uilabel(app.GridLayout);
            app.BlockSelectedLabel.Layout.Row = 7;
            app.BlockSelectedLabel.Layout.Column = [2 3];
            app.BlockSelectedLabel.Text = 'Label3';

            % Create ImagesetLabel
            app.ImagesetLabel = uilabel(app.GridLayout);
            app.ImagesetLabel.Layout.Row = 9;
            app.ImagesetLabel.Layout.Column = 1;
            app.ImagesetLabel.Text = 'Imageset';

            % Create ImagesetNameLabel
            app.ImagesetNameLabel = uilabel(app.GridLayout);
            app.ImagesetNameLabel.Layout.Row = 9;
            app.ImagesetNameLabel.Layout.Column = [2 3];
            app.ImagesetNameLabel.Text = 'Label4';

            % Create SelectImagesButton
            app.SelectImagesButton = uibutton(app.GridLayout, 'push');
            app.SelectImagesButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImagesButtonPushed, true);
            app.SelectImagesButton.Enable = 'off';
            app.SelectImagesButton.Layout.Row = 9;
            app.SelectImagesButton.Layout.Column = 4;
            app.SelectImagesButton.Text = 'Select Images';

            % Create OverridesPanel
            app.OverridesPanel = uipanel(app.GridLayout);
            app.OverridesPanel.Title = 'Overrides';
            app.OverridesPanel.Layout.Row = 10;
            app.OverridesPanel.Layout.Column = [1 3];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.OverridesPanel);
            app.GridLayout3.ColumnWidth = {'1x', '3x', '3x', '3x'};
            app.GridLayout3.RowHeight = {22.02, 22.02, 'fit', 'fit', 'fit', 'fit'};

            % Create Stim1XYOverride
            app.Stim1XYOverride = uicheckbox(app.GridLayout3);
            app.Stim1XYOverride.ValueChangedFcn = createCallbackFcn(app, @Stim1XYOverrideValueChanged, true);
            app.Stim1XYOverride.Text = '';
            app.Stim1XYOverride.Layout.Row = 1;
            app.Stim1XYOverride.Layout.Column = 1;

            % Create Stim1XYEditFieldLabel
            app.Stim1XYEditFieldLabel = uilabel(app.GridLayout3);
            app.Stim1XYEditFieldLabel.HorizontalAlignment = 'right';
            app.Stim1XYEditFieldLabel.Layout.Row = 1;
            app.Stim1XYEditFieldLabel.Layout.Column = 2;
            app.Stim1XYEditFieldLabel.Text = 'Stim1  X,Y';

            % Create Stim1XEditField
            app.Stim1XEditField = uieditfield(app.GridLayout3, 'numeric');
            app.Stim1XEditField.AllowEmpty = 'on';
            app.Stim1XEditField.Layout.Row = 1;
            app.Stim1XEditField.Layout.Column = 3;
            app.Stim1XEditField.Value = [];

            % Create Stim1YEditField
            app.Stim1YEditField = uieditfield(app.GridLayout3, 'numeric');
            app.Stim1YEditField.AllowEmpty = 'on';
            app.Stim1YEditField.Layout.Row = 1;
            app.Stim1YEditField.Layout.Column = 4;
            app.Stim1YEditField.Value = [];

            % Create Stim2XYOverride
            app.Stim2XYOverride = uicheckbox(app.GridLayout3);
            app.Stim2XYOverride.ValueChangedFcn = createCallbackFcn(app, @Stim2XYOverrideValueChanged, true);
            app.Stim2XYOverride.Text = '';
            app.Stim2XYOverride.Layout.Row = 2;
            app.Stim2XYOverride.Layout.Column = 1;

            % Create Stim2XYEditFieldLabel
            app.Stim2XYEditFieldLabel = uilabel(app.GridLayout3);
            app.Stim2XYEditFieldLabel.HorizontalAlignment = 'right';
            app.Stim2XYEditFieldLabel.Layout.Row = 2;
            app.Stim2XYEditFieldLabel.Layout.Column = 2;
            app.Stim2XYEditFieldLabel.Text = 'Stim2 X,Y';

            % Create Stim2XEditField
            app.Stim2XEditField = uieditfield(app.GridLayout3, 'numeric');
            app.Stim2XEditField.AllowEmpty = 'on';
            app.Stim2XEditField.Layout.Row = 2;
            app.Stim2XEditField.Layout.Column = 3;
            app.Stim2XEditField.Value = [];

            % Create Stim2YEditField
            app.Stim2YEditField = uieditfield(app.GridLayout3, 'numeric');
            app.Stim2YEditField.AllowEmpty = 'on';
            app.Stim2YEditField.Layout.Row = 2;
            app.Stim2YEditField.Layout.Column = 4;
            app.Stim2YEditField.Value = [];

            % Create SampTimeOverride
            app.SampTimeOverride = uicheckbox(app.GridLayout3);
            app.SampTimeOverride.ValueChangedFcn = createCallbackFcn(app, @SampTimeOverrideValueChanged, true);
            app.SampTimeOverride.Text = '';
            app.SampTimeOverride.Layout.Row = 3;
            app.SampTimeOverride.Layout.Column = 1;

            % Create SampTimesEditFieldLabel
            app.SampTimesEditFieldLabel = uilabel(app.GridLayout3);
            app.SampTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.SampTimesEditFieldLabel.Layout.Row = 3;
            app.SampTimesEditFieldLabel.Layout.Column = 2;
            app.SampTimesEditFieldLabel.Text = 'Samp Time(s)';

            % Create SampTimesEditField
            app.SampTimesEditField = uieditfield(app.GridLayout3, 'numeric');
            app.SampTimesEditField.AllowEmpty = 'on';
            app.SampTimesEditField.Layout.Row = 3;
            app.SampTimesEditField.Layout.Column = 3;
            app.SampTimesEditField.Value = [];

            % Create GapTimeOverride
            app.GapTimeOverride = uicheckbox(app.GridLayout3);
            app.GapTimeOverride.ValueChangedFcn = createCallbackFcn(app, @GapTimeOverrideValueChanged, true);
            app.GapTimeOverride.Text = '';
            app.GapTimeOverride.Layout.Row = 4;
            app.GapTimeOverride.Layout.Column = 1;

            % Create GapTimesEditFieldLabel
            app.GapTimesEditFieldLabel = uilabel(app.GridLayout3);
            app.GapTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.GapTimesEditFieldLabel.Layout.Row = 4;
            app.GapTimesEditFieldLabel.Layout.Column = 2;
            app.GapTimesEditFieldLabel.Text = 'Gap Time (s)';

            % Create GapTimesEditField
            app.GapTimesEditField = uieditfield(app.GridLayout3, 'numeric');
            app.GapTimesEditField.AllowEmpty = 'on';
            app.GapTimesEditField.Layout.Row = 4;
            app.GapTimesEditField.Layout.Column = 3;
            app.GapTimesEditField.Value = [];

            % Create TestTimeOverride
            app.TestTimeOverride = uicheckbox(app.GridLayout3);
            app.TestTimeOverride.ValueChangedFcn = createCallbackFcn(app, @TestTimeOverrideValueChanged, true);
            app.TestTimeOverride.Text = '';
            app.TestTimeOverride.Layout.Row = 5;
            app.TestTimeOverride.Layout.Column = 1;

            % Create TestTimesEditFieldLabel
            app.TestTimesEditFieldLabel = uilabel(app.GridLayout3);
            app.TestTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.TestTimesEditFieldLabel.Layout.Row = 5;
            app.TestTimesEditFieldLabel.Layout.Column = 2;
            app.TestTimesEditFieldLabel.Text = 'Test Time(s)';

            % Create TestTimesEditField
            app.TestTimesEditField = uieditfield(app.GridLayout3, 'numeric');
            app.TestTimesEditField.AllowEmpty = 'on';
            app.TestTimesEditField.Layout.Row = 5;
            app.TestTimesEditField.Layout.Column = 3;
            app.TestTimesEditField.Value = [];

            % Create RespTimeOverride
            app.RespTimeOverride = uicheckbox(app.GridLayout3);
            app.RespTimeOverride.ValueChangedFcn = createCallbackFcn(app, @RespTimeOverrideValueChanged, true);
            app.RespTimeOverride.Text = '';
            app.RespTimeOverride.Layout.Row = 6;
            app.RespTimeOverride.Layout.Column = 1;

            % Create RespTimesEditFieldLabel
            app.RespTimesEditFieldLabel = uilabel(app.GridLayout3);
            app.RespTimesEditFieldLabel.HorizontalAlignment = 'right';
            app.RespTimesEditFieldLabel.Layout.Row = 6;
            app.RespTimesEditFieldLabel.Layout.Column = 2;
            app.RespTimesEditFieldLabel.Text = 'Resp Time (s)';

            % Create RespTimesEditField
            app.RespTimesEditField = uieditfield(app.GridLayout3, 'numeric');
            app.RespTimesEditField.AllowEmpty = 'on';
            app.RespTimesEditField.Layout.Row = 6;
            app.RespTimesEditField.Layout.Column = 3;
            app.RespTimesEditField.Value = [];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ethodlg_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end