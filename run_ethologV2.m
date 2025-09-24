
function results = run_ethologV2(varargin)
%run_etholog_single Run etholog for a specific block
%   Detailed explanation goes here

    goalDirectedTypes = {'none', 'existing', 'stim1', 'stim2'};
    testingTypes = {'no-test', 'desk', 'booth', 'mangun-desk', 'mangun-booth'};
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

    % always millikey, unless we're at the mangun lab
    responseType = 'MilliKey';
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
                image_folder = '/data/cclab/images/Babies';
            end
            output_folder = '/home/cclab/Desktop/cclab/ethdata/output';
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
            kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
        case 'booth'
            % Set these folders according to the current machine
            if ~isempty(p.Results.ImageFolder)
                image_folder = p.Results.ImageFolder;
            else
                image_folder = '/data/cclab/images/Babies';
            end
            output_folder = '/home/cclab/Desktop/cclab/ethdata/output';
            eyelinkDummyMode=1;   % 0 for participant, 1 for dummy mode
            screenDimensions=[];
            screenDistance=[];
            screenNumber = 1;
            screenRect=[];
            % This may need to be changed if workign inside booth
            if ~p.Results.Inside
                kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
            else
                kbind = getKeyboardIndex('Dell Dell USB Keyboard');
                eyelinkDummyMode=0;   % 0 for participant, 1 for dummy mode
            end
        case 'mangun-desk'
            % Set these folders according to the current machine
            if isempty(p.Results.ImageFolder)
                image_folder = 'pass_img_as_argument';
            else
                image_folder = p.Results.ImageFolder;
            end
            output_folder = 'c:/work/cclab/data/output';
            eyelinkDummyMode=1;   % 0 for participant, 1 for dummy mode
            screenDimensions=[];
            screenDistance=[];
            screenNumber = 1;
            %screenRect=[1120,300,1920,900];
            screenRect=[];
            % My desktop kbd
            kbind = getKeyboardIndex('Keyboard');
            responseType = 'SharedKbd';
        case 'mangun-booth'
            % Set these folders according to the current machine
            if isempty(p.Results.ImageFolder)
                image_folder = 'pass_img_as_argument';
            else
                image_folder = p.Results.ImageFolder;
            end
            output_folder = 'c:/work/cclab/data/output';
            eyelinkDummyMode=0;   % 0 for participant, 1 for dummy mode
            screenDimensions=[];
            screenDistance=[];
            screenNumber = 1;
            %screenRect=[1120,300,1920,900];
            screenRect=[];
            % My desktop kbd
            kbind = getKeyboardIndex('Keyboard');
            responseType = 'SharedKbd';

    end            
      


    % load imageset
    % old default img=imageset(image_folder, 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
    if isempty(p.Results.Images)
        img=imageset(image_folder,{'params'});
    else
        img = p.Results.Images;
    end

    % Millikey index (todo - test!)
    %mkind = cclabGetMilliKeyIndices();
    mkind = 0;
    warning('Using same kbd for millikey and experimenter input!');
    
        
    
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .12);
%     save('input/contrast_60_single_a_lrn_12.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .12);
%     save('input/contrast_60_single_b_lrn_12.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .12);
%     save('input/contrast_60_single_c_lrn_12.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(100:109), [1,1,1,1]', .78, .16);
%     save('input/contrast_60_single_TEST_a.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(100:109), [1,1,1,1]', .78, .16);
%     save('input/contrast_60_single_TEST_b.mat', 'blocks', 'inputArgs', 'parsedResults');    

%      [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(100:109), [2,2,2,2]', .78, .16, 'SampTime', 1.0, 'TestTime', 1.0);
%      save('input/contrast_60_single_DEMO_LONG_a.mat', 'blocks', 'inputArgs', 'parsedResults')
%
%      trials = generateThreshBlock(imgbw.BalancedFileKeys, 5, 'HL', .8, [0, .04, .08, .12], 1);
%
% img=imageset(image_folder,{'params'});
% trials=generateThreshBlockProcImage(img.BalancedFileKeys, 5)
% run_etholog_single('test','thr','Test','desk','Trials',trials,'Threshold',true,'ImageTest',true,'ImageFolder','/home/dan/work/cclab/images/eth/babies_match_V2')






    args = {
        'Screen', screenNumber, ...
        'Rect', screenRect, ...
        'Response', responseType, ...
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

    % for mangun lab, we will use the io64 device for input/output to the
    % eeg recording
    if strcmp(p.Results.Test, 'mangun-desk')
        args{end+1} = 'UseIO64';
        args{end+1} = true;
        args{end+1} = 'GetEDF';
        args{end+1} = false;
    end
    if strcmp(p.Results.Test, 'mangun-booth')
        args{end+1} = 'UseIO64';
        args{end+1} = true;
        args{end+1} = 'GetEDF';
        args{end+1} = true;
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