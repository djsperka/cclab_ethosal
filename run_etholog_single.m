function results = run_etholog_single(varargin)
%run_etholog_single Run etholog for a specific block
%   Detailed explanation goes here

    blockTypes = {'left', 'right', 'none'};
    testingTypes = {'no-test', 'desk', 'booth'}
    p=inputParser;
    p.addRequired('ID', @(x) ischar(x));
    p.addRequired('lrn', @(x) ismember(x,blockTypes));
    p.addParameter('Test', 'no-test', @(x) ismember(x, testingTypes));
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
    p.addParameter('Inside', false, @(x) islogical(x));
    p.addParameter('Trials', [], @(x) istable(x));
    p.parse(varargin{:});

    blockIndex = find(ismember(blockTypes, lower(p.Results.lrn)));
    blockType = blockTypes{blockIndex};

    switch(p.Results.Test)
        case 'desk'
            % Set these folders according to the current machine
            image_folder = '/home/dan/work/cclab/images/eth/Babies';
            input_folder = '/home/dan/work/cclab/ethdata/input';
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
            image_folder = '/data/cclab/images/Babies';
            input_folder = '/home/cclab/Desktop/ethosal/input';
            output_folder = '/home/cclab/Desktop/ethosal/output';
            eyelinkDummyMode=0;   % 0 for participant, 1 for dummy mode
            screenDimensions=[598, 336];
            screenDistance=920;
            screenNumber = 1;
            screenRect=[];
            % This is the keyboard in use at the booth
            kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
        case 'booth'
            % Set these folders according to the current machine
            image_folder = '/data/cclab/images/Babies';
            input_folder = '/home/cclab/Desktop/ethosal/input';
            output_folder = '/home/cclab/Desktop/ethosal/output';
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
      


    outputFilename = fullfile(output_folder, [p.Results.ID, '_', blockType, '.mat']);
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
    img=imageset(image_folder, 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
    
    % load trial blocks
    cc=load(fullfile(input_folder, 'contrast_60_single_a.mat'));
    
    % Millikey index (todo - test!)
    mkind = cclabGetMilliKeyIndices();
    
        
    
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .16);
%     save('input/contrast_60_single_a_lrn.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .16);
%     save('input/contrast_60_single_b_lrn.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(1:100), [24,6,24,6; 6,24,6,24; 15,15,15,15]', .78, .16);
%     save('input/contrast_60_single_c_lrn.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(100:109), [1,1,1,1]', .78, .16);
%     save('input/contrast_60_single_TEST_a.mat', 'blocks', 'inputArgs', 'parsedResults')
%     [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(imgbw.BalancedFileKeys(100:109), [1,1,1,1]', .78, .16);
%     save('input/contrast_60_single_TEST_b.mat', 'blocks', 'inputArgs', 'parsedResults');    

    if isempty(p.Results.Trials)
        t=cc.blocks{blockIndex};
    else
        t=p.Results.Trials;
    end

    results=ethologSingleTest(t, img, screenDimensions, screenDistance, ...
                                'ImageChangeType', 'contrast', ...
                                'Screen', screenNumber, ...
                                'Rect', screenRect, ...
                                'OutputFile', outputFilename, ...
                                'Response', 'MilliKey', ...
                                'MilliKeyIndex', mkind, ...
                                'KeyboardIndex', kbind, ...
                                'Beep', true, ...
                                'EyelinkDummyMode', eyelinkDummyMode, ...
                                'SkipSyncTests', 1);
end
    %save('/home/cclab/Desktop/ethosal/output/jodi-240-a.mat', 'results');