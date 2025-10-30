
function results = run_ethologV2(varargin)
%run_etholog_single Run etholog for a specific block
%   Detailed explanation goes here

    goalDirectedTypes = {'none', 'existing', 'stim1', 'stim2'};
    testingTypes = {'no-test', 'desk', 'booth'};
    p=inputParser;
    p.addRequired('ID', @(x) ischar(x));
    p.addParameter('Test', 'no-test', @(x) ismember(x, testingTypes));
    p.addParameter('ScreenDistance', [], @(x) isscalar(x) && isnumeric(x)); % can be empty
    p.addParameter('ScreenWH', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && length(x)==2));
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
    p.addParameter('Inside', false, @(x) islogical(x));
    p.addParameter('Trials', [], @(x) isValidEthologTrialsInput(x));
    p.addParameter('GoalDirected', 'none', @(x) ismember(x, goalDirectedTypes));
    p.addParameter('StartBlock', 1, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('Threshold', false, @(x) islogical(x));
    p.addParameter('ExperimentTestType', 'Image', @(x) ischar(x));
    p.addParameter('ImageFolder','', @(x) ischar(x));
    p.addParameter('Images', [], @(x) isa(x, 'imageset'));
    p.addParameter('Beep', false, @(x) islogical(x));
    p.addParameter('Stim1XY', [], @(x) isvector(x) && length(x)==2);
    p.addParameter('Stim2XY', [], @(x) isvector(x) && length(x)==2);

    p.parse(varargin{:});

    switch(p.Results.Test)
        case 'desk'
            % Set these folders according to the current machine
            if isempty(p.Results.ImageFolder)
                image_folder = '/home/dan/work/cclab/images/eth/Babies';
            else
                image_folder = p.Results.ImageFolder;
            end
            output_folder = '/home/dan/work/cclab/ethdata/output';
            eyelinkDummyMode=1;   % 0 for participant, 1 for dummy mode
            screenDimensions=[];
            screenDistance=[];
            screenNumber = 0;
            screenRect=[1120,300,1920,900];
            % My desktop kbd
            kbind = getKeyboardIndex('Dell Dell USB Keyboard');
        case 'no-test'
            % Set these folders according to the current machine
            if ~isempty(p.Results.ImageFolder)
                image_folder = p.Results.ImageFolder;
            else
                image_folder = 'C:/Users/cclab/Desktop/work/cclab-images/MoreBabies';
            end
            output_folder = 'C:/Users/cclab/Desktop/work/data/output';
            eyelinkDummyMode=0;   % 0 for participant, 1 for dummy mode

            screenDimensions=[598, 336];
            if ~isempty(p.Results.ScreenWH)
                screenDimensions = p.Results.ScreenWH;
            end
            screenDistance=920;
            if ~isempty(p.Results.ScreenDistance)
                screenDistance = p.Results.ScreenDistance;
            end
            screenNumber = 1;
            screenRect=[];
            % This is the keyboard in use at the booth
            %kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
            kbind = 0;
        case 'booth'
            % Set these folders according to the current machine
            if ~isempty(p.Results.ImageFolder)
                image_folder = p.Results.ImageFolder;
            else
                image_folder = 'C:/Users/cclab/Desktop/work/cclab-images/MoreBabies';
            end
            output_folder = 'C:/Users/cclab/Desktop/work/data/output';
            eyelinkDummyMode=1;   % 0 for participant, 1 for dummy mode
            screenDimensions=[];
            screenDistance=[];
            screenNumber = 1;
            screenRect=[];
            kbind = 0;  % windows
            % % This may need to be changed if workign inside booth
            % if ~p.Results.Inside
            %     kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
            % else
            %     kbind = getKeyboardIndex('Dell Dell USB Keyboard');
            %     eyelinkDummyMode=0;   % 0 for participant, 1 for dummy mode
            % end
    end            
      


    % load imageset
    % old default img=imageset(image_folder, 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
    if isempty(p.Results.Images)
        img=imageset(image_folder,{'params'});
    else
        img = p.Results.Images;
    end

    % Millikey index

    if IsWin()
        mkind = 0;
    else
        mkind = cclabGetMilliKeyIndices();  % probably won't work right
        % Under ubuntu 2024 the millikey presents 3 values here instead of 1. 
        % The first one seems to be the one to use, so let's just choose that
        % one.
        if length(mkind)>1
            fprintf('Millikey presents 3 devices in PsychHID. Choosing the first index (%d)', mkind(1));
            mkind = mkind(1);
        end
    end
    



    args = {
        'Screen', screenNumber, ...
        'Rect', screenRect, ...
        'Response', 'MilliKey', ...
        'MilliKeyIndex', mkind, ...
        'KeyboardIndex', kbind, ...
        'Beep', false, ...
        'EyelinkDummyMode', eyelinkDummyMode, ...
        'SkipSyncTests', 1, ...
        'Threshold', p.Results.Threshold, ...
        'Beep', p.Results.Beep, ...
        'ExperimentTestType', p.Results.ExperimentTestType, ...
        'StartBlock', p.Results.StartBlock
        };

    if ~ismember('Stim1XY', p.UsingDefaults)
        args{end+1} = 'Stim1XY';
        args{end+1} = p.Results.Stim1XY;
    end

    if ~ismember('Stim2XY', p.UsingDefaults)
        args{end+1} = 'Stim2XY';
        args{end+1} = p.Results.Stim2XY;
    end


    if ~eyelinkDummyMode
        args{end+1} = 'EDFFolder';
        args{end+1} = output_folder;
    end


    % If a blockset is being passed, then outputFilename should be the
    % output folder. The 'tag' will be used to form a filename for each
    % block. 

    if istable(p.Results.Trials)

        % Must supply the entire output filename. 
        % Also supply GoalDirected arg. 

        outputFilename = fullfile(output_folder, [p.Results.ID, '.mat']);
        if isfile(outputFilename)
            warning('OutputFile %s already exists. Finding a suitable name...', outputFilename);
            [path, base, ext] = fileparts(outputFilename);
            [ok, outputFilename] = makeNNNFilename(path, [base, '_NNN', ext]);
            if ~ok
                error('Cannot form usable filename using folder %s and basename %s', p.Results.Folder, [base, '_NNN', ext]);
            end
        end
        fprintf('\n*** Using output filename %s\n', outputFilename);

        args{end+1} = 'OutputFile';
        args{end+1} = outputFilename;
        args{end+1} = 'GoalDirected';
        args{end+1} = p.Results.GoalDirected;

    else
        % Output filename will be formed inside of etholog, so supply the
        % components of the filename: subjectID, output folder. The
        % date-time string is generated when each block is run. The
        % additional part of the filename: filebase_blk# is passed in the
        % 'outputbase' field of the blockset struct (see makeBlockset.m)

        args{end+1} = 'OutputFolder';
        args{end+1} = output_folder;
        args{end+1} = 'SubjectID';
        args{end+1} = p.Results.ID;
    end










    results=ethologV2(p.Results.Trials, img, screenDimensions, screenDistance, args{:});

    % results=ethologV2(t, img, screenDimensions, screenDistance, ...
    %                             'Screen', screenNumber, ...
    %                             'Rect', screenRect, ...
    %                             'OutputFile', outputFilename, ...
    %                             'Response', 'MilliKey', ...
    %                             'MilliKeyIndex', mkind, ...
    %                             'KeyboardIndex', kbind, ...
    %                             'Beep', false, ...
    %                             'EyelinkDummyMode', eyelinkDummyMode, ...
    %                             'SkipSyncTests', 1, ...
    %                             'Threshold', p.Results.Threshold, ...
    %                             'ExperimentTestType', p.Results.ExperimentTestType);
end
    %save('/home/cclab/Desktop/ethosal/output/jodi-240-a.mat', 'results');
