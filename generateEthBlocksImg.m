function [trialsOrBlocks, inputArgs, parsedResults]  = generateEthBlocksImg(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    
    p.addRequired('NumImages', @(x) isnumeric(x) && isvector(x) && length(x)<3);
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('TestKeys', {},  @(x) iscellstr(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('NumBlocks', 1, @(x) isscalar(x) && x>0);

    p.parse(varargin{:});
    parsedResults = p.Results;
    inputArgs = varargin;

    % First we select images. The number of images selected for left-change
    % and right-change is in 'NumImages'. If its a scalar, use the value
    % for both left and right. Can have an unbalanced set, if you like. 
    %
    % Each set will have change and no-change trials spread across each
    % combination.

    replacements = cell(4,1);
    columnNames=cell(4,1);

    nImages = p.Results.NumImages;
    if isscalar(nImages)
        nImages(2) = nImages(1);
    end
    nTotalImages = sum(nImages);
    imageIndices = randperm(length(p.Results.FileKeys), nTotalImages);

    % Now set up trials for left-change. 
    replacements{1} = reshape(p.Results.FileKeys(imageIndices(1:nImages(1))), nImages(1), 1);
    columnNames{1} = 'ImageKey';

    % salience
    replacements{2}={p.Results.FolderKeys{1}; p.Results.FolderKeys{2}};
    columnNames{2} = 'Folder1Key';

    % salience
    replacements{3}={p.Results.FolderKeys{1}; p.Results.FolderKeys{2}};
    columnNames{3} = 'Folder2Key';

    % change/nochange test
    StimTestType = 1;
    replacements{4} = [0;StimTestType];
    columnNames{4} = 'StimChangeType';

    % This generates trials with things distributed over the elements of
    % names/reps.
    t1 = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);

    % StimTestType
    t1.StimTestType = ones(height(t1), 1) * StimTestType;

    % Now set up trials for left-change. 
    replacements{1} = reshape(p.Results.FileKeys(imageIndices(nImages(1)+1:nImages(1)+nImages(2))), nImages(2), 1);
    StimTestType = 2;
    replacements{4} = [0;StimTestType];
    t2 = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);

    % StimTestType
    t2.StimTestType = ones(height(t2), 1) * StimTestType;

    % combine t1 and t2, then randomize....
    trialsOrBlocks = [t1;t2];
    trialsOrBlocks = trialsOrBlocks(randperm(height(trialsOrBlocks)), :);
    nTrials = height(trialsOrBlocks);
   

    % StimKeys
    trialsOrBlocks.Stim1Key = imageset.make_keys(trialsOrBlocks.Folder1Key, trialsOrBlocks.ImageKey);
    trialsOrBlocks.Stim2Key = imageset.make_keys(trialsOrBlocks.Folder2Key, trialsOrBlocks.ImageKey);
    trialsOrBlocks.StimPairType = strcat(trialsOrBlocks.Folder1Key, trialsOrBlocks.Folder2Key);

    % StimTestKey

    % nochange trials get same as first stim
    trialsOrBlocks.StimTestKey =  cell(height(trialsOrBlocks), 1);
    tmp = trialsOrBlocks.StimChangeType==0 & trialsOrBlocks.StimTestType==1;
    trialsOrBlocks.StimTestKey(tmp) = trialsOrBlocks.Stim1Key(tmp);
    tmp = trialsOrBlocks.StimChangeType==0 & trialsOrBlocks.StimTestType==2;
    trialsOrBlocks.StimTestKey(tmp) = trialsOrBlocks.Stim2Key(tmp);

    % trials that change
    ctmp = char(trialsOrBlocks.Folder1Key);
    tmp = trialsOrBlocks.StimChangeType==1 & ctmp==p.Results.FolderKeys{1};
    trialsOrBlocks.StimTestKey(tmp) = imageset.make_keys(p.Results.TestKeys(1), trialsOrBlocks.ImageKey(tmp));
    tmp = trialsOrBlocks.StimChangeType==1 & ctmp==p.Results.FolderKeys{2};
    trialsOrBlocks.StimTestKey(tmp) = imageset.make_keys(p.Results.TestKeys(2), trialsOrBlocks.ImageKey(tmp));

    ctmp = char(trialsOrBlocks.Folder2Key);
    tmp = trialsOrBlocks.StimChangeType==2 & ctmp==p.Results.FolderKeys{1};
    trialsOrBlocks.StimTestKey(tmp) = imageset.make_keys(p.Results.TestKeys(1), trialsOrBlocks.ImageKey(tmp));
    tmp = trialsOrBlocks.StimChangeType==2 & ctmp==p.Results.FolderKeys{2};
    trialsOrBlocks.StimTestKey(tmp) = imageset.make_keys(p.Results.TestKeys(2), trialsOrBlocks.ImageKey(tmp));

    % base value
    trialsOrBlocks.Base = generateColumn(nTrials, 100);

    % etc
    trialsOrBlocks.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
    trialsOrBlocks.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
    trialsOrBlocks.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
    trialsOrBlocks.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
    trialsOrBlocks.SampTime = generateColumn(nTrials, p.Results.SampTime);
    trialsOrBlocks.GapTime = generateColumn(nTrials, p.Results.GapTime);
    trialsOrBlocks.RespTime = generateColumn(nTrials, p.Results.RespTime);
    trialsOrBlocks.TestTime = generateColumn(nTrials, p.Results.TestTime);

    % results
    trialsOrBlocks.Started = false(nTrials, 1);
    trialsOrBlocks.trialIndex = zeros(nTrials, 1);
    trialsOrBlocks.Aon = generateColumn(nTrials, -1);
    trialsOrBlocks.Aoff = generateColumn(nTrials, -1);
    trialsOrBlocks.Bon = generateColumn(nTrials, -1);
    trialsOrBlocks.Boff = generateColumn(nTrials, -1);
    trialsOrBlocks.tResp = generateColumn(nTrials, -1);
    trialsOrBlocks.iResp = -1*ones(nTrials, 1);


    % checkif we need to break into blocks
    if p.Results.NumBlocks > 1
        % I want to make sure there's no rounding error on the last one, 
        % so I force the last element to be the height.
        endIndex = round(cumsum(ones(1, p.Results.NumBlocks)/p.Results.NumBlocks) * nTrials);
        endIndex(p.Results.NumBlocks) = nTrials;    
        blocks = cell(p.Results.NumBlocks, 1);
        lastEnd = 0;
        for iblock=1:p.Results.NumBlocks
            blocks{iblock} = trialsOrBlocks(lastEnd+1:endIndex(iblock), :);
            fprintf('Block %d has %d elements\n', iblock, height(blocks{iblock}));
            lastEnd = endIndex(iblock);
        end
        trialsOrBlocks = blocks;
    end
end


function [A] = generateColumn(n, valueOrRange)
% generateColumn - generate a column of n values. If 'valueOrRange' is
% scalar, all n values are set to it. If 'valueOrRange' is a two-element
% vector, it should be a range within which the values should vall - they
% are drawn from a uniform distribtion.

    if length(valueOrRange)==1
        A = valueOrRange * ones(n, 1);
    else
        A = valueOrRange(1) + (valueOrRange(2)-valueOrRange(1)) * rand(n, 1);
    end
end

