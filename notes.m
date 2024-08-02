% % load imageset of babies for contrast 
% imgContrast=imageset('/data/cclab/images/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal);
% 
% % load imageset for lum changes. These are squeezed&clamped on load.
% clampRegion = [0, 225];
% imgClamp = imageset('/data/cclab/images/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @(I) squeezeclampimage(I,clampRegion));
% 
% % Use the imageset to generate a set of threshold trials using contrast
% thrConTrials = generateThreshBlock(imgContrast.BalancedFileKeys, 10, 'HL', .7, [0 .1 .2 .3], 1);
% thrConTrials.StimChangeType(thrConTrials.Delta==0) = 0;
% 
% % Dimensions, all in mm
% screen_dimensions = [598, 336];
% screen_distance = 1000;
% mkind = cclabGetMilliKeyIndices;
% kbind = 11;
% mywr = [1120, 300, 1920, 900];
% 
% 
% % run on rig (screen 1) testing only. Using mkey
% results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, ...
%     'ImageChangeType', 'contrast', ...
%     'Screen', 1, ...
%     'Response', 'MilliKey', ...
%     'MilliKeyIndex', mkind, ...
%     'KeyboardIndex', kbind, ...
%     'Beep', true, ...
%     'EyelinkDummyMode', 1, ...
%     'SkipSyncTests', 1);
% results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% 
% 
% results=etholog(blocks{1}, imgbw, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 0, 'Rect', mywr, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% 
% results=etholog(ethBlocks{1}, imgbw, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 0, 'Rect', mywr, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% 
% 
% 
% ethBlocks = generateEthBlocks(imgContrast.BalancedFileKeys, [30, 10, 20;10, 30, 20; 20, 20, 20]', 20);
% 
% 
% mkind = cclabGetMilliKeyIndices();
% 
% % xinput -list
% % [ind, names, allinf] = GetKeyboardIndices();
% 
% kbind = 10;
% screen_dimensions=[598, 336];
% screen_distance=1000;
% 
% results=etholog(thrConTrials, imgContrast, [], [], 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, 'ImageChangeType', 'contrast', 'Screen', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% 
% results=etholog(thrConTrials, 'Images', imgContrast75, 'Screen', 1, 'Name', 'est002', 'Fovx', 45, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Beep', true, 'EyelinkDummyMode', 1, 'SkipSyncTests', 1);
% 
% 
% results=etholog(thrConTrials, imgContrast, screen_dimensions, screen_distance, ...
%     'ImageChangeType', 'contrast', ...
%     'Screen', 1, ...
%     'Response', 'MilliKey', ...
%     'MilliKeyIndex', mkind, ...
%     'KeyboardIndex', kbind, ...
%     'Beep', true, ...
%     'EyelinkDummyMode', 0, ...
%     'SkipSyncTests', 1);
% 
% 
% 
% 
% [blocks,inputArgs,parsedResults]=generateEthBlocks(img.BalancedFileKeys, [30,10,20;10,30,20;20,20,20]', .78, .22);
% save(NAME_HERE, 'blocks', 'inputArgs', 'parsedResults');
% 
% 
% 
% %==========================================================
% % 2024-07-11
% 
% % generate regular trials for delta=20 "modified image" test. 
% % imageset must be the set Xiaomo made with multiple contrast levels. 
% % The params() function sets the H and L to be mid-range, ImageProc20, and
% % we take the "change" to be ImageProc40.
% 
% [blocks,inputArgs,parsedResults]=generateEthBlocksSingleTest(img.BalancedFileKeys, [24,6,24,6;6,24,6,24;15,15,15,15]',0,6,'FolderKeys',{'H';'Q'},'TestKeys',{'J';'S'});
% save('/home/dan/work/cclab/ethdata/input/modimage_gabor6_lrn_blocks_A.mat', 'blocks','inputArgs','parsedResults');
% [blocks,inputArgs,parsedResults]=generateEthBlocksSingleTest(img.BalancedFileKeys, [24,6,24,6;6,24,6,24;15,15,15,15]',0,6,'FolderKeys',{'H';'Q'},'TestKeys',{'J';'S'});
% save('/home/dan/work/cclab/ethdata/input/modimage_gabor6_lrn_blocks_B.mat', 'blocks','inputArgs','parsedResults');
% 
% run_etholog_single('test','thr','Test','desk','Trials',blocks{1},'Threshold',false,'ExperimentTestType','Image','ImageFolder','/home/dan/work/cclab/images/eth/babies_match_V2')







%%%%%%%%%%%%%%%%%%%%%%%%%
%dan@bucky:~/work/cclab/ethosal$ cat ~/Documents/MATLAB/mylocal.m 
% ethDataRoot='/home/dan/work/cclab/ethdata/';
% ethImgRoot='/home/dan/work/cclab/cclab-images/';

local_ethosal   % ethDataRoot, ethImgRoot
img=imageset(fullfile(ethImgRoot,'babies_match_V2'),'params');

% for debug, machine must have Computer Vision Toolbox.
img=imageset(fullfile(ethImgRoot,'babies_match_V2'),{'params'},'ShowName',true);

blocks=generateThreshBlockProcImage(img.BalancedFileKeys, 40, 'Threshold', true,'NumBlocks',3);

% save blocks and imageset name/paramsfunc. The names here matter! 
S.blocks=blocks
S.Name=img.Name
S.ParamsFunc=img.ParamsFunc
save(fullfile(ethDataRoot,'input','mimg_thr_5_00-40-B.mat'),'-struct','S');

%%%%%%%%%%%%%%%%%%%%%%%%%

blocks=generateThreshBlockProcImage(img.BalancedFileKeys, 5, 'Threshold', false, 'NumBlocks', 3);
run_etholog_single('test','thr','Test','desk','Trials',blocks{1},'Threshold',true,'ExperimentTestType','Image','ImageFolder','/home/dan/work/cclab/images/eth/babies_match_V2')



timg=imageset(fullfile(ethImgRoot,'babies_match_V2'),'tparams');
blocks=generateThreshBlockGabor(timg.BalancedFileKeys, 30, [2,4,6,8],'TestTime',0.1,'NumBlocks', 3);
clear S
S.blocks=blocks;
S.imagesetName = timg.Name;
S.imagesetParamsFunc = timg.ParamsFunc;
save(fullfile(ethDataRoot,'input','gab_thr_30-2468-A.mat'),'-struct','S');


run_etholog_single('test','thr','Test','desk','Trials',blocks{1},'Threshold',true,'ExperimentTestType','Gabor','Images',timg);




%%%%%%%%%%%%%%%%%%
% generate regular trials for mimg
% 
%
% dan@bucky:~/work/cclab/ethosal$ cat /home/dan/work/cclab/cclab-images/babies_match_V2/mimg_params.m
% function Y = mimg_params()
%     Y.Subfolders={ ...
%     'H','Nature/HistMatch0';'L','Texture/HistMatch0';'h','Nature/HistMatch25';'l','Texture/HistMatch25'
%     };
% end



img=imageset(fullfile(ethImgRoot,'babies_match_V2'),'mimg_params_20');
[blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(img.BalancedFileKeys, [25,25,25,25]',0,6,'FolderKeys',{'H';'L'},'TestKeys',{'h';'l'}, 'NumBlocks', 2);
S.trials=blocks{1};
S.imagesetName=img.Name;
S.imagesetParamsFunc=img.ParamsFunc;
save(fullfile(ethDataRoot,'input','mimg_exp_50img-20chg-D.mat'), '-struct', 'S');


% for gabor
[blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(img.BalancedFileKeys, [33,33,33;33,33,33]',0,6,'FolderKeys',{'H';'L'}, 'NumBlocks', 2);
S.imagesetName = img.Name
S.imagesetParamsFunc = img.ParamsFunc
S.blocks = blocks{1};
save(fullfile(ethDataRoot,'input','gab_exp_33x3-A.mat'), '-struct', 'S');
S.blocks = blocks{2};
save(fullfile(ethDataRoot,'input','gab_exp_33x3-B.mat'), '-struct', 'S');