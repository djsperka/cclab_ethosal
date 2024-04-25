% load imageset of babies for contrast 
imgContrast=imageset('/data/cclab/images/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);

% load imageset for lum changes. These are squeezed&clamped on load.
clampRegion = [0, 225];
imgClamp = imageset('/data/cclab/images/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @(I) squeezeclampimage(I,clampRegion));

% Use the imageset to generate a set of threshold trials using contrast
thrConTrials = generateThreshBlock(imgContrast.BalancedFileKeys, 10, 'HL', .7, [0 .1 .2 .3], 1);
thrConTrials.StimChangeType(thrConTrials.Delta==0) = 0;

% Dimensions, all in mm
screen_dimensions = [598, 336];
screen_distance = 1000;
mkind = cclabGetMilliKeyIndices;
kbind = 11;
mywr = [1120, 300, 1920, 900];


% run on rig (screen 1) testing only. Using mkey
results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, ...
    'ImageChangeType', 'contrast', ...
    'Screen', 1, ...
    'Response', 'MilliKey', ...
    'MilliKeyIndex', mkind, ...
    'KeyboardIndex', kbind, ...
    'Beep', true, ...
    'EyelinkDummyMode', 1, ...
    'SkipSyncTests', 1);
results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);


results=etholog(blocks{1}, imgbw, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 0, 'Rect', mywr, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);

results=etholog(ethBlocks{1}, imgbw, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 0, 'Rect', mywr, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);



ethBlocks = generateEthBlocks(imgContrast.BalancedFileKeys, [30, 10, 20;10, 30, 20; 20, 20, 20]', 20);


mkind = cclabGetMilliKeyIndices();

% xinput -list
% [ind, names, allinf] = GetKeyboardIndices();

kbind = 10;
screen_dimensions=[598, 336];
screen_distance=1000;

results=etholog(thrConTrials, imgContrast, [], [], 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);

results=etholog(thrConTrials, 'Images', imgContrast75, 'Screen', 1, 'Name', 'est002', 'Fovx', 45, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);


results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, ...
    'ImageChangeType', 'contrast', ...
    'Screen', 1, ...
    'Response', 'MilliKey', ...
    'MilliKeyIndex', mkind, ...
    'KeyboardIndex', kbind, ...
    'Beep', true, ...
    'EyelinkDummyMode', 0, ...
    'SkipSyncTests', 1);




[blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [30,10,20;10,30,20;20,20,20]', .78, .22);
save(NAME_HERE, 'blocks', 'inputArgs', 'parsedResults');