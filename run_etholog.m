% input folder
input_folder = '/home/cclab/Desktop/ethosal/input';
output_folder = '/home/cclab/Desktop/ethosal/output';

% % generate trials - 60 images
% [blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [30,10,20;10,30,20;20,20,20]', .78, .22);
% 
% % generate trials - 30 images
% [blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [15,5,10;5,15,10;10,10,10]', .78, .22);
% save(fullfile(output_folder, 'contrast_30images_a.mat'), 'blocks', 'inputArgs', 'parsedResults');
% 
% save(NAME_HERE, 'blocks', 'inputArgs', 'parsedResults');

% Screen
PsychDefaultSetup(2);
[w,wr]=PsychImaging('OpenWindow', 1, [.5 .5 .5]');

% load imageset
img=imageset('/data/cclab/images/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
cc=load('/home/cclab/Desktop/ethosal/input/contrast_30images_a.mat');


% parameters needed
mkind = cclabGetMilliKeyIndices();
kbind = 11;
screen_dimensions=[598, 336];
screen_distance=1000;
dummy_mode=1;   % 0 for participant

results=etholog(cc.blocks{1}, img, screen_dimensions, screen_distance, ...
    'ImageChangeType', 'contrast', ...
    'Screen', 1, ...
    'Response', 'MilliKey', ...
    'MilliKeyIndex', mkind, ...
    'KeyboardIndex', kbind, ...
    'Beep', true, ...
    'EyelinkDummyMode', dummy_mode, ...
    'SkipSyncTests', 1);