% This script used to generate color cued input files. The numbers are
% hard-coded, change for your purposes. 

% Multiplicities by type. Each 3-element row corresponds to a set of
% trials. If multiple rows are present, then the same ordering of the
% images are used for the generation of each row. 
% The value in column 1 is the number of image pairs (a pair is high&low 
% salience images) for balanced tests, where both test conditions are
% tested. The values in columns 2&3 are the number of image pairs where
% only condition 1 is tested, or only condition 2 is tested, respectively. 
% If 'UseColorCues' is true, the test condtions are the CueColors used in
% ethologV2 (see CueColors arg - default is red, green). If 'UseColorCues'
% is false (default), then condition 1 is Stim1 directional test (normally
% left), and condition2 is Stim2 (normally right). 
MultsByType = [10,30,0;10,0,30];

%imageset
local_ethosal;
img=imageset(fullfile(ethImgRoot, 'MoreBabies'), 'paramsCircEdge256');
[blocks,inputArgs,parsedResults,scriptName]=generateEthBlocksImgV2( ...
    img.BalancedFileKeys, [10,30,0;10,0,30], ...
    'FlipPair', true, ...
    'NumBlocks', 8, ...
    'CueSide', [1;2], ...
    'UseColorCues', true, ...
    'FolderKeys', {'H';'L'});




file1 = makeEthologInput(ethDataRoot, 'rimg', 'exp', 'ColorCue-30-10-c1', img, blocks{1}, inputArgs, parsedResults,scriptName);
file2 = makeEthologInput(ethDataRoot, 'rimg', 'exp', 'ColorCue-30-10-c2', img, blocks{2}, inputArgs, parsedResults,scriptName);
file3 = makeBlockset(file1, file2, 'C');