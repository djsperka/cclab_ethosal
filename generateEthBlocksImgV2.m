function [trialsOrBlocks, inputArgs, parsedResults]  = generateEthBlocksImgV2(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    

    % For regular trials this is the number of pairs. 
    % For threshold trials, this is the number of images to use.
    p.addRequired('Num', @(x) isnumeric(x) && isvector(x) && length(x)<3);
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('TestKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('NumBlocks', 1, @(x) isscalar(x) && x>0);

    p.addOptional('Threshold', false, @(x) islogical(x));
    p.addOptional('Side', 1, @(x) isscalar(x) && ismember(x,[1,2]));
    p.addOptional('Base', 5, @(x) isnumeric(x));

    p.parse(varargin{:});
    parsedResults = p.Results;
    inputArgs = varargin;

    % make convenience vars
    FolderKeys = p.Results.FolderKeys;
    TestKeys = p.Results.TestKeys;
    FileKeys = p.Results.FileKeys;
    nFileKeys = length(FileKeys);


    %% Regular trials - not threshold

    % The number of trials will be 16*nPairs
    % where 16 = (left folder key)*(right folder
    % key)*(StimTestType=1,2)*(StimChangeTF=0,1)

    if ~p.Results.Threshold

        replacements = cell(6,1);
        columnNames=cell(6,1);
    
        % Select the images that will be used
        nPairs = p.Results.Num;
        imagePairs=reshape(randperm(nFileKeys, nPairs*2), [nPairs,2]);

        % Which image pair to use on a given trial?
        replacements{1} = (1:nPairs)';
        columnNames{1} = 'ImagePairIndex';
    
        % Folder1Key
        replacements{2}=p.Results.FolderKeys;
        columnNames{2} = 'Folder1Key';
    
        % Folder2Key
        replacements{3}=p.Results.FolderKeys;
        columnNames{3} = 'Folder2Key';
    
        % TestType? L=1, R=2
        replacements{4}=[1;2];
        columnNames{4} = 'StimTestType';
    
        % change/nochange test
        replacements{5} = [0;1];
        columnNames{5} = 'StimChangeTF';
    
        % Base value (for rotations)
        replacements{6} = p.Results.Base;
        columnNames{6} = 'Base';
    
    
        % This generates trials with things distributed over the elements of
        % names/reps.
        tabTemp = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);
        nTrials = height(tabTemp);
    
    
        % Now make File1Key and File2Key
        tabTemp.File1Key = FileKeys(imagePairs(tabTemp.ImagePairIndex,1));
        tabTemp.File2Key = FileKeys(imagePairs(tabTemp.ImagePairIndex,2));
    
        % StimA1Key and StimA2Key
        tabTemp.StimA1Key = imageset.make_keys(tabTemp.Folder1Key, tabTemp.File1Key);
        tabTemp.StimA2Key = imageset.make_keys(tabTemp.Folder2Key, tabTemp.File2Key);
    
        % StimChangeType
        tabTemp.StimChangeType = tabTemp.StimChangeTF.*tabTemp.StimTestType;
    
        % Initial orientation
        tabTemp.Stim1Ori = (2*randi([0 1],nTrials, 1))-1;
        tabTemp.Stim2Ori = (2*randi([0 1],nTrials, 1))-1;
    
        %% Now make B stim keys. 
        % First, initialize all of them to 'BKGD'. 
        StimB1Key=cell(size(tabTemp.StimA1Key));
        [StimB1Key{:}] = deal('BKGD');
        StimB2Key=cell(size(tabTemp.StimA1Key));
        [StimB2Key{:}] = deal('BKGD');
    
        % logical arrays for trials where stim1/Stim2 changes
        ncL1 = tabTemp.StimTestType==1 & ~tabTemp.StimChangeTF;
        ncL2 = tabTemp.StimTestType==2 & ~tabTemp.StimChangeTF;
    
        % For no-change trials, the B key is same as A key.
        StimB1Key(ncL1) = tabTemp.StimA1Key(ncL1);
        StimB2Key(ncL2) = tabTemp.StimA2Key(ncL2);
    
        % Make an index pointing to the correct index in FileKeys/TestKeys
        [~,indA1] = ismember(tabTemp.Folder1Key, FolderKeys);
        [~,indA2] = ismember(tabTemp.Folder2Key, FolderKeys);
        tabTemp.indA1 = indA1;
        tabTemp.indA2 = indA2;
    
        % logical arrays for trials where stim1/Stim2 changes
        L1 = tabTemp.StimTestType==1 & tabTemp.StimChangeTF;
        L2 = tabTemp.StimTestType==2 & tabTemp.StimChangeTF;
    
        % Make StimB keys
        if any(L1)
            StimB1Key(L1) = imageset.make_keys(TestKeys(indA1(L1)), tabTemp.File1Key(L1));
        end
        if any(L2)
            StimB2Key(L2) = imageset.make_keys(TestKeys(indA2(L2)), tabTemp.File2Key(L2));
        end
        tabTemp.StimB1Key = StimB1Key;
        tabTemp.StimB2Key = StimB2Key;
    
        % Make life easier when analyzing data by assigning the "scientific"
        % trial type HH,HL,LH,LL
        folderKeyIndices = horzcat(indA1, indA2);
        hl={'H','L'};
    
        % logical arrays for trials stim1/Stim2 is test type (regardless of 
        % whether it changes)
        L1 = tabTemp.StimTestType==1;
        L2 = tabTemp.StimTestType==2;
    
        sciTrialType = cell(height(tabTemp), 1);
    
        sciTrialType(L1) = strcat(hl(indA1(L1)), hl(indA2(L1)));
        sciTrialType(L2) = strcat(hl(indA2(L2)), hl(indA1(L2)));
        tabTemp.sciTrialType = sciTrialType;

    else

        %% Threshold trials

        % The number of trials will be 8*nImages*nBase
        % where 8 = (folder key)*(StimTestType=1,2)*(StimChangeTF=0,1)
        % and nBase is the number of Base values tested.

        replacements = cell(5,1);
        columnNames=cell(5,1); 
    
        % Which image pair to use on a given trial?
        nImages = p.Results.Num;
        imageInd=randperm(nFileKeys, nImages);

        % Initial orientation direction for each image
        imageOri = (2*randi([0 1],nImages, 1))-1;


        % now randomize params
        %replacements{1} = reshape(randperm(nFileKeys, nImages), nImages, 1);
        replacements{1} = (1:nImages)';
        columnNames{1} = 'ImageIndex';
    
        % FolderKey
        replacements{2}=p.Results.FolderKeys;
        columnNames{2} = 'FolderKey';
    
        % TestType? L=1, R=2
        replacements{3}=[1;2];
        columnNames{3} = 'StimTestType';
    
        % change/nochange test
        replacements{4} = [0;1];
        columnNames{4} = 'StimChangeTF';
    
        % Base value (for rotations)
        replacements{5} = p.Results.Base;
        columnNames{5} = 'Base';
    
        tabTemp = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);
        nTrials = height(tabTemp);

        % Log array for stim on left(1) and right(2).
        L1=tabTemp.StimTestType==1;
        L2=tabTemp.StimTestType==2;

        Stim1Key=cell(nTrials, 1);
        Stim2Key=cell(nTrials, 1);
        Stim1Key(L1)=imageset.make_keys(tabTemp.FolderKey(L1), FileKeys(imageInd(tabTemp.ImageIndex(L1))));
        Stim1Key(~L1)={'BKGD'};
        Stim2Key(L2)=imageset.make_keys(tabTemp.FolderKey(L2), FileKeys(imageInd(tabTemp.ImageIndex(L2))));
        Stim2Key(~L2)={'BKGD'};

        tabTemp.StimA1Key = Stim1Key;
        tabTemp.StimB1Key = Stim1Key;
        tabTemp.StimA2Key = Stim2Key;
        tabTemp.StimB2Key = Stim2Key;


        Stim1Ori = zeros(nTrials, 1);
        Stim1Ori(L1) = imageOri(tabTemp.ImageIndex(L1));
        Stim2Ori = zeros(nTrials, 1);
        Stim2Ori(L2) = imageOri(tabTemp.ImageIndex(L2));
        tabTemp.Stim1Ori = Stim1Ori;
        tabTemp.Stim2Ori = Stim2Ori;


    end




    
    
    trialsOrBlocks = tabTemp;
    
    % base value
    %tabTemp.Base = generateColumn(nTrials, p.Results.Base);

    % etc
    tabTemp.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
    tabTemp.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
    tabTemp.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
    tabTemp.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
    tabTemp.SampTime = generateColumn(nTrials, p.Results.SampTime);
    tabTemp.GapTime = generateColumn(nTrials, p.Results.GapTime);
    tabTemp.RespTime = generateColumn(nTrials, p.Results.RespTime);
    tabTemp.TestTime = generateColumn(nTrials, p.Results.TestTime);

    % results
    tabTemp.Started = false(nTrials, 1);
    tabTemp.trialIndex = (1:nTrials)';
    tabTemp.tAon = generateColumn(nTrials, -1);
    tabTemp.tAoff = generateColumn(nTrials, -1);
    tabTemp.tBon = generateColumn(nTrials, -1);
    tabTemp.tBoff = generateColumn(nTrials, -1);
    tabTemp.tResp = generateColumn(nTrials, -1);
    tabTemp.iResp = -1*ones(nTrials, 1);


    % checkif we need to break into blocks
    if p.Results.NumBlocks > 1
        % I want to make sure there's no rounding error on the last one, 
        % so I force the last element to be the height.
        endIndex = round(cumsum(ones(1, p.Results.NumBlocks)/p.Results.NumBlocks) * nTrials);
        endIndex(p.Results.NumBlocks) = nTrials;    
        blocks = cell(p.Results.NumBlocks, 1);
        lastEnd = 0;
        for iblock=1:p.Results.NumBlocks
            blocks{iblock} = tabTemp(lastEnd+1:endIndex(iblock), :);
            fprintf('Block %d has %d elements\n', iblock, height(blocks{iblock}));
            lastEnd = endIndex(iblock);
        end
        trialsOrBlocks = blocks;
    else
        trialsOrBlocks = tabTemp;
    end
end


function [A] = generateColumn(n, valueOrRange)
% generateColumn - generate a column of n values. If 'valueOrRange' is
% scalar, all n values are set to it. If 'valueOrRange' is a two-element
% vector, it should be a range within which the values should vall - they
% are drawn from a uniform distribtion.

    if isscalar(valueOrRange)
        A = valueOrRange * ones(n, 1);
    else
        A = valueOrRange(1) + (valueOrRange(2)-valueOrRange(1)) * rand(n, 1);
    end
end

