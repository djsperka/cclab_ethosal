
% goal directed
img=imageset(fullfile(ethImgRoot, 'MoreBabies'), '/home/dan/work/cclab/ethosal/paramsCircEdge256.m');
[blocks,inputArgs,parsedResults,scriptName]=generateEthBlocksImgV2(img.BalancedFileKeys, [20,60,0;20,0,60], Base=4, FlipPair=true,NumBlocks=8,CueSide=[1;2]);

makeEthologInput(ethDataRoot,'rimg','exp','60-20-left-A',img,blocks{1},inputArgs,parsedResults,scriptName)
makeEthologInput(ethDataRoot,'rimg','exp','60-20-right-A',img,blocks{2},inputArgs,parsedResults,scriptName)

% not goal directed
img=imageset(fullfile(ethImgRoot, 'MoreBabies'), '/home/dan/work/cclab/ethosal/paramsCircEdge256_3types');