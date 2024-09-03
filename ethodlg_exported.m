classdef ethodlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        UseboothkbdCheckBox      matlab.ui.control.CheckBox
        ScrDistmmEditField       matlab.ui.control.EditField
        ScrDistmmEditFieldLabel  matlab.ui.control.Label
        ShowImageNamesCheckBox   matlab.ui.control.CheckBox
        SelectBlockButton        matlab.ui.control.Button
        ExitButton               matlab.ui.control.Button
        RunButton                matlab.ui.control.Button
        SelectImagesButton       matlab.ui.control.Button
        ImagesetNameLabel        matlab.ui.control.Label
        ImagesetLabel            matlab.ui.control.Label
        BlockSelectedLabel       matlab.ui.control.Label
        LocationDropDown         matlab.ui.control.DropDown
        LocationLabel            matlab.ui.control.Label
        SubjectIDEditField       matlab.ui.control.EditField
        SubjectIDEditFieldLabel  matlab.ui.control.Label
        BlockLabel               matlab.ui.control.Label
        TrialsFileLabel          matlab.ui.control.Label
        TrialsLabel              matlab.ui.control.Label
        SelectTrialsButton       matlab.ui.control.Button
        ThresholdCheckBox        matlab.ui.control.CheckBox
        TesttypeButtonGroup      matlab.ui.container.ButtonGroup
        RotatedImageButton       matlab.ui.control.RadioButton
        GaborButton              matlab.ui.control.RadioButton
        ImageButton              matlab.ui.control.RadioButton
    end

    
    properties (Access = private)
        pathDataRoot % root folder for input/output data
        pathImgRoot % root folder for imageset
        isFileSelected % set to true when trial/blocks file is chosen
        filePath % path of trials/blocks file
        fileName % basename of trials/blocks file
        fileNBlocks % number of blocks in trials file
        fileBlockIndex % which block in file, or 0 if none selected
        isImagesetSelected % set to true when images selected
        imagesetName % Name of imageset to use
        imagesetParamsFunc % Paramsfunc to use when loading imageset
        Y % input file loaded. Will contain blocks or trials et al.
        isTrialsSelected % file is selected, and a block also if needed
    end
    
    methods (Access = private)
        
        function updateFileBlocks(app)
            if app.isFileSelected
                app.TrialsFileLabel.Text = app.fileName;
                if app.fileNBlocks > 0
                    if app.fileBlockIndex <= app.fileNBlocks
                        app.BlockSelectedLabel.Text = sprintf('%d/%d', app.fileBlockIndex, app.fileNBlocks);
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
            else
                me = MException('ethodlg:nofile', 'Input blocks/trials file is not selected.');
                throw(me);
            end
        end
        
        function ttype = getTestType(app)
            if app.GaborButton.Value
                ttype = 'Gabor';
            elseif app.ImageButton.Value
                ttype = 'Image';
            elseif app.RotatedImageButton.Value
                ttype = 'RotatedImage';
            else
                ttype = 'Unknown';
            end
        end
        
        function isReady = checkRunButton(app)
            isReady = ~isempty(app.SubjectIDEditField.Value) && app.isImagesetSelected && app.isTrialsSelected;
            app.RunButton.Enable = isReady;
        end
        
        function selectBlockNumberDialog(app)
            % make a cell array with the numeric values 1:nBlocks, and
            % the last value is 'None Selected'
            C=[cellfun(@(x) sprintf('%d',x), num2cell(1:app.fileNBlocks),UniformOutput=false),{'None Selected'}];
            if app.isFileSelected && app.fileNBlocks>0
                if app.fileBlockIndex < app.fileNBlocks && app.fileBlockIndex > 0
                    initialValue = app.fileBlockIndex;
                else
                    initialValue = length(C);
                end
            else
                initialValue = length(C);
            end
            [indexSelected,tf]=listdlg(PromptString='Select a block',ListString=C,SelectionMode='single',ListSize=[150, 25*length(C)],InitialValue=initialValue);
            if tf
                app.fileBlockIndex = indexSelected;
                if indexSelected <= app.fileNBlocks
                    app.isTrialsSelected = true;
                else
                    app.isTrialsSelected = false;
                end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, ethDataRoot, ethImgRoot)

            app.pathDataRoot = ethDataRoot;
            app.pathImgRoot = ethImgRoot;
            app.isFileSelected = false;
            app.isImagesetSelected = false;
            app.imagesetName = '';
            app.imagesetParamsFunc = '';
            app.fileBlockIndex = -1;
            app.fileNBlocks = -1;
            app.Y = [];
            app.isTrialsSelected = false;
            app.RunButton.Enable = false;
            updateFileBlocks(app);

        end

        % Button pushed function: SelectTrialsButton
        function LoadTrialsPushed(app, event)
            if app.ImageButton.Value
                ttype = 'mimg';
            elseif app.RotatedImageButton.Value
                ttype = 'rimg';
            elseif app.GaborButton.Value
                ttype = 'gab';
            else
                % should not happen with radio buttons
                ttype = 'unk';
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
                
                if any(contains(fieldnames(app.Y), 'blocks'))
                    app.fileNBlocks = length(app.Y.blocks);
                    app.selectBlockNumberDialog();
                elseif any(contains(fieldnames(app.Y), 'trials'))
                    app.fileNBlocks = 0;
                    app.fileBlockIndex = 0;
                    app.isTrialsSelected = true;
                else
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

                % form id for output filename

                [~, base, ~] = fileparts(app.fileName);
                if app.fileNBlocks > 0
                    blok = sprintf('%s_blk%d', base, app.fileBlockIndex);
                else
                    blok = sprintf('%s', base);
                end
                id = [char(datetime('now','Format','yyyy-MM-dd-HHmm')), '_', app.SubjectIDEditField.Value, '_', blok];

                % The value from screen distance comes to us as a char array
                % 
                fprintf('Screen distance (ignored) %d\n', str2num(app.ScrDistmmEditField.Value));


                run_ethologV2(id, 'Test', app.LocationDropDown.Value, 'Trials', app.getSelectedTrials(), 'Threshold', app.ThresholdCheckBox.Value, 'ExperimentTestType', app.getTestType(), 'Images', img, 'Inside', app.UseboothkbdCheckBox.Value);
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

        % Selection changed function: TesttypeButtonGroup
        function TesttypeButtonGroupSelectionChanged(app, event)
            selectedButton = app.TesttypeButtonGroup.SelectedObject;
            
            % Test type changed, clear out file and imageset
            if app.isImagesetSelected
                app.isImagesetSelected = false;
                app.imagesetName = '';
                app.imagesetParamsFunc = '';
            end

            if app.isFileSelected
                app.isFileSelected = false;
                app.fileName = '';
                app.filePath = '';
                app.fileNBlocks = 0;
                app.fileBlockIndex = 0;
                app.isTrialsSelected = false;
            end

            app.updateFileBlocks();
            app.checkRunButton();
            drawnow;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 401 393];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'40x', '30x', '30x'};
            app.GridLayout.RowHeight = {24, 22, 24, '45x', '30x', '15x', 22, 22, 23, 24, 24};

            % Create TesttypeButtonGroup
            app.TesttypeButtonGroup = uibuttongroup(app.GridLayout);
            app.TesttypeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @TesttypeButtonGroupSelectionChanged, true);
            app.TesttypeButtonGroup.Title = 'Test type';
            app.TesttypeButtonGroup.Layout.Row = [2 4];
            app.TesttypeButtonGroup.Layout.Column = 1;

            % Create ImageButton
            app.ImageButton = uiradiobutton(app.TesttypeButtonGroup);
            app.ImageButton.Text = 'Image';
            app.ImageButton.Position = [11 64 58 22];
            app.ImageButton.Value = true;

            % Create GaborButton
            app.GaborButton = uiradiobutton(app.TesttypeButtonGroup);
            app.GaborButton.Text = 'Gabor';
            app.GaborButton.Position = [13 23 65 22];

            % Create RotatedImageButton
            app.RotatedImageButton = uiradiobutton(app.TesttypeButtonGroup);
            app.RotatedImageButton.Text = 'Rotated Image';
            app.RotatedImageButton.Position = [12 43 101 22];

            % Create ThresholdCheckBox
            app.ThresholdCheckBox = uicheckbox(app.GridLayout);
            app.ThresholdCheckBox.Text = 'Threshold?';
            app.ThresholdCheckBox.Layout.Row = 2;
            app.ThresholdCheckBox.Layout.Column = 2;

            % Create SelectTrialsButton
            app.SelectTrialsButton = uibutton(app.GridLayout, 'push');
            app.SelectTrialsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadTrialsPushed, true);
            app.SelectTrialsButton.Layout.Row = 7;
            app.SelectTrialsButton.Layout.Column = 3;
            app.SelectTrialsButton.Text = 'Select Trials';

            % Create TrialsLabel
            app.TrialsLabel = uilabel(app.GridLayout);
            app.TrialsLabel.Layout.Row = 7;
            app.TrialsLabel.Layout.Column = 1;
            app.TrialsLabel.Text = 'Trials:';

            % Create TrialsFileLabel
            app.TrialsFileLabel = uilabel(app.GridLayout);
            app.TrialsFileLabel.Layout.Row = 7;
            app.TrialsFileLabel.Layout.Column = 2;

            % Create BlockLabel
            app.BlockLabel = uilabel(app.GridLayout);
            app.BlockLabel.Layout.Row = 8;
            app.BlockLabel.Layout.Column = 1;
            app.BlockLabel.Text = 'Block:';

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

            % Create LocationLabel
            app.LocationLabel = uilabel(app.GridLayout);
            app.LocationLabel.Layout.Row = 5;
            app.LocationLabel.Layout.Column = 1;
            app.LocationLabel.Text = 'Location:';

            % Create LocationDropDown
            app.LocationDropDown = uidropdown(app.GridLayout);
            app.LocationDropDown.Items = {'Booth (test)', 'Booth (subj)', 'Desk'};
            app.LocationDropDown.ItemsData = {'booth', 'no-test', 'desk', 'ERR'};
            app.LocationDropDown.Layout.Row = 5;
            app.LocationDropDown.Layout.Column = 2;
            app.LocationDropDown.Value = 'booth';

            % Create BlockSelectedLabel
            app.BlockSelectedLabel = uilabel(app.GridLayout);
            app.BlockSelectedLabel.Layout.Row = 8;
            app.BlockSelectedLabel.Layout.Column = 2;
            app.BlockSelectedLabel.Text = 'Label3';

            % Create ImagesetLabel
            app.ImagesetLabel = uilabel(app.GridLayout);
            app.ImagesetLabel.Layout.Row = 9;
            app.ImagesetLabel.Layout.Column = 1;
            app.ImagesetLabel.Text = 'Imageset';

            % Create ImagesetNameLabel
            app.ImagesetNameLabel = uilabel(app.GridLayout);
            app.ImagesetNameLabel.Layout.Row = 9;
            app.ImagesetNameLabel.Layout.Column = 2;
            app.ImagesetNameLabel.Text = 'Label4';

            % Create SelectImagesButton
            app.SelectImagesButton = uibutton(app.GridLayout, 'push');
            app.SelectImagesButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImagesButtonPushed, true);
            app.SelectImagesButton.Layout.Row = 9;
            app.SelectImagesButton.Layout.Column = 3;
            app.SelectImagesButton.Text = 'Select Images';

            % Create RunButton
            app.RunButton = uibutton(app.GridLayout, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Layout.Row = 11;
            app.RunButton.Layout.Column = 2;
            app.RunButton.Text = 'Run';

            % Create ExitButton
            app.ExitButton = uibutton(app.GridLayout, 'push');
            app.ExitButton.ButtonPushedFcn = createCallbackFcn(app, @ExitButtonPushed, true);
            app.ExitButton.Layout.Row = 11;
            app.ExitButton.Layout.Column = 3;
            app.ExitButton.Text = 'Exit';

            % Create SelectBlockButton
            app.SelectBlockButton = uibutton(app.GridLayout, 'push');
            app.SelectBlockButton.ButtonPushedFcn = createCallbackFcn(app, @SelectBlockButtonPushed, true);
            app.SelectBlockButton.Layout.Row = 8;
            app.SelectBlockButton.Layout.Column = 3;
            app.SelectBlockButton.Text = 'Select Block';

            % Create ShowImageNamesCheckBox
            app.ShowImageNamesCheckBox = uicheckbox(app.GridLayout);
            app.ShowImageNamesCheckBox.Text = 'Show Image Names (test only)';
            app.ShowImageNamesCheckBox.Layout.Row = 3;
            app.ShowImageNamesCheckBox.Layout.Column = 2;

            % Create ScrDistmmEditFieldLabel
            app.ScrDistmmEditFieldLabel = uilabel(app.GridLayout);
            app.ScrDistmmEditFieldLabel.Layout.Row = 6;
            app.ScrDistmmEditFieldLabel.Layout.Column = 1;
            app.ScrDistmmEditFieldLabel.Text = 'Scr Dist (mm)';

            % Create ScrDistmmEditField
            app.ScrDistmmEditField = uieditfield(app.GridLayout, 'text');
            app.ScrDistmmEditField.InputType = 'digits';
            app.ScrDistmmEditField.Placeholder = '(default)';
            app.ScrDistmmEditField.Layout.Row = 6;
            app.ScrDistmmEditField.Layout.Column = 2;

            % Create UseboothkbdCheckBox
            app.UseboothkbdCheckBox = uicheckbox(app.GridLayout);
            app.UseboothkbdCheckBox.Text = 'Use booth kbd (test only)';
            app.UseboothkbdCheckBox.Layout.Row = 4;
            app.UseboothkbdCheckBox.Layout.Column = 2;

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