local_ethosal
img=imageset(fullfile(ethImgRoot, 'MoreBabies'), 'paramsCircEdge256');

CueSide = [1;2];
FlipPair = true;
FolderKeys = {'H';'L'};
GapTime = 1.75;
Num = [10, 30, 0; 10, 0, 30];
NumBlocks = 2;
FileNamePartLeft = 'babies10both30left';
FileNamePartRight = 'babies10both30right';
FileNamePartCombined = 'babies10both30combined';

% CueSide = [1;2];
% FlipPair = true;
% FolderKeys = {'H';'L'};
% GapTime = 1.75;
% Num = [1, 3, 0; 1, 0, 3];
% NumBlocks = 2;
% FileNamePartLeft = 'shortbabies1both3left';
% FileNamePartRight = 'shortbabies1both3right';
% FileNamePartCombined = 'shortbabies1both3combined';


[allTrialSets, inputArgs, parsedResults, scriptName]  = generateEthBlocksImgV2(img.BalancedFileKeys, Num, 'CueSide', CueSide, 'FlipPair', FlipPair, 'FolderKeys', FolderKeys, 'GapTime', GapTime, 'NumBlocks', NumBlocks);

leftFilename = makeEthologInput(ethDataRoot, 'rimg', 'exp', FileNamePartLeft, img, allTrialSets{1}, inputArgs, parsedResults, scriptName);
rightFilename = makeEthologInput(ethDataRoot, 'rimg', 'exp', FileNamePartRight, img, allTrialSets{2}, inputArgs, parsedResults, scriptName);
combinedFilename = makeBlockset(leftFilename, rightFilename, FileNamePartCombined);