function results = run_etholog_single(varargin)
%run_etholog_single Run etholog for a specific block
%   Detailed explanation goes here

    testingTypes = {'no-test', 'desk', 'booth'};
    p=inputParser;
    p.addRequired('ID', @(x) ischar(x));
    p.addParameter('Test', 'no-test', @(x) ismember(x, testingTypes));
    p.addParameter('ScreenDistance', [], @(x) isscalar(x) && isnumeric(x)); % can be empty
    p.addParameter('ScreenWH', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && length(x)==2));
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
    p.addParameter('Inside', false, @(x) islogical(x));
    p.addParameter('Trials', [], @(x) istable(x));
    p.addParameter('Threshold', false, @(x) islogical(x));
    p.addParameter('ExperimentTestType', 'Image', @(x) ischar(x));
    p.addParameter('ImageFolder','', @(x) ischar(x));
    p.addParameter('Images', [], @(x) isa(x, 'imageset'));
    p.parse(varargin{:});

    switch(p.Results.Test)
        case 'desk'
            % Set these folders according to the current machine
            if length(p.Results.ImageFolder) > 0
                image_folder = p.Results.ImageFolder;
            else
                image_folder = '/home/dan/work/cclab/images/eth/Babies';
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
            if length(p.Results.ImageFolder) > 0
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
            if length(p.Results.ImageFolder) > 0
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
    end            
      


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


    % load imageset
    % old default img=imageset(image_folder, 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
    if isempty(p.Results.Images)
        img=imageset(image_folder,{'params'});
    else
        img = p.Results.Images;
    end
    
    t=p.Results.Trials;


    % Millikey index (todo - test!)
    mkind = cclabGetMilliKeyIndices();
    
        
    
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



    results=ethologV2(t, img, screenDimensions, screenDistance, ...
                                'Screen', screenNumber, ...
                                'Rect', screenRect, ...
                                'OutputFile', outputFilename, ...
                                'Response', 'MilliKey', ...
                                'MilliKeyIndex', mkind, ...
                                'KeyboardIndex', kbind, ...
                                'Beep', true, ...
                                'EyelinkDummyMode', eyelinkDummyMode, ...
                                'SkipSyncTests', 1, ...
                                'Threshold', p.Results.Threshold, ...
                                'ExperimentTestType', p.Results.ExperimentTestType);
end
    %save('/home/cclab/Desktop/ethosal/output/jodi-240-a.mat', 'results');