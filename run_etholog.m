function results = run_etholog(identifier, lrn)
%run_etholog Run etholog for a specific block
%   Detailed explanation goes here

    blockTypes = {'left', 'right', 'none'};
    if ~ischar(identifier) || ~any(ismember(blockTypes, lower(lrn)))
        error('expecting char inputs');
    end
    blockIndex = find(ismember(blockTypes, lower(lrn)));
    blockType = blockTypes{blockIndex};

    % Set these folders according to the current machine
    image_folder = '/data/cclab/images/Babies';
    input_folder = '/home/cclab/Desktop/ethosal/input';
    output_folder = '/home/cclab/Desktop/ethosal/output';

    outputFilename = fullfile(output_folder, [identifier, '_', blockType, '.mat']);
    if isfile(outputFilename)
        warning('OutputFile %s already exists. Finding a suitable name...', outputFilename);
        [path, base, ext] = fileparts(outputFilename);
        [ok, outputFilename] = makeNNNFilename(fullfile(path, [base, '_NNN', ext]));
        if ~ok
            error('Cannot form usable filename using folder %s and basename %s', p.Results.Folder, [base, '_NNN', ext]);
        end
    end
    fprintf('\n*** Using output filename %s\n', outputFilename);


    % load imageset
    img=imageset(image_folder, 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
    
    % load trial blocks
    cc=load(fullfile(input_folder, 'contrast_60images_d16.mat'));
    
    % Millikey index (todo - test!)
    mkind = cclabGetMilliKeyIndices();
    
    % keyboard index (todo - test)
    
    % This is the keyboard in use at the booth
    %kbind = getKeyboardIndex('Dell KB216 Wired Keyboard');
    
    % keyboard inside the booth
    kbind = getKeyboardIndex('Dell Dell USB Keyboard');
    
    screen_dimensions=[598, 336];
    screen_distance=1000;
    dummy_mode=0;   % 0 for participant, 1 for dummy mode
        
    
    % % generate trials - 60 images
    % [blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [30,10,20;10,30,20;20,20,20]', .78, .22);
    % 
    % % generate trials - 30 images
    % [blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [15,5,10;5,15,10;10,10,10]', .78, .22);
    % save(fullfile(output_folder, 'contrast_30images_a.mat'), 'blocks', 'inputArgs', 'parsedResults');
    % 
    % save(NAME_HERE, 'blocks', 'inputArgs', 'parsedResults');
    
    % Screen
    %PsychDefaultSetup(2);
    %[w,wr]=PsychImaging('OpenWindow', 1, [.5 .5 .5]');
    
    
    
    
    
    results=etholog(cc.blocks{blockIndex}, img, screen_dimensions, screen_distance, ...
        'ImageChangeType', 'contrast', ...
        'Screen', 1, ...
        'OutputFile', outputFilename, ...
        'Response', 'MilliKey', ...
        'MilliKeyIndex', mkind, ...
        'KeyboardIndex', kbind, ...
        'Beep', true, ...
        'EyelinkDummyMode', dummy_mode, ...
        'SkipSyncTests', 1);

end
    %save('/home/cclab/Desktop/ethosal/output/jodi-240-a.mat', 'results');