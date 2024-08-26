function [trialsOrBlocks, inputArgs, parsedResults]  = generateEthBlocksImgV2(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    
    p.addRequired('NumPairs', @(x) isnumeric(x) && isvector(x) && length(x)<3);
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


    replacements = cell(4,1);
    columnNames=cell(4,1);

    nImages = length(p.Results.FileKeys);
    nPairs = p.Results.NumPairs;
    imagePairs = reshape(randperm(nImages, nPairs*2), nPairs, 2);

    % Now set up trials for left-change. 
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

    % This generates trials with things distributed over the elements of
    % names/reps.
    tabTemp = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);
    nTrials = height(tabTemp);

    i1=imagePairs(:,1);
    i2=imagePairs(:,2);
    % tabTemp.Stim1Key(logT1) = imageset.make_keys(tabTemp.Folder1Key(logT1), p.Results.FileKeys(i1(tabTemp.ImagePairIndex(logT1))));
    % tabTemp.Stim2Key(logT2) = imageset.make_keys(tabTemp.Folder2Key(logT2), p.Results.FileKeys(i2(tabTemp.ImagePairIndex(logT2))));
    tabTemp.Stim1Key = imageset.make_keys(tabTemp.Folder1Key, p.Results.FileKeys(i1(tabTemp.ImagePairIndex)));
    tabTemp.Stim2Key = imageset.make_keys(tabTemp.Folder2Key, p.Results.FileKeys(i2(tabTemp.ImagePairIndex)));

    % StimChangeType
    tabTemp.StimChangeType = tabTemp.StimChangeTF.*tabTemp.StimTestType;

    % make StimTestKey
    % I can't figure out how to do this in a pretty way, so lets do it ugly
    StimTestKey = cell(height(tabTemp), 1);
    for i=1:height(tabTemp)
        if tabTemp.StimChangeTF(i)
            %fprintf('%d %d %d %s %s\n', tabTemp.StimTestType(i), tabTemp.ImagePairIndex(i), ...
            %imagePairs(tabTemp.ImagePairIndex(i), tabTemp.StimTestType(i)), ...
            %p.Results.TestKeys{tabTemp.StimTestType(i)}, ...
            %p.Results.FileKeys{imagePairs(tabTemp.ImagePairIndex(i), tabTemp.StimTestType(i))});
            if tabTemp.StimTestType(i) == 1
                kk = strmatch(tabTemp.Folder1Key(i), p.Results.FolderKeys);
            elseif tabTemp.StimTestType(i) == 2
                kk = strmatch(tabTemp.Folder2Key(i), p.Results.FolderKeys);
            end
            StimTestKey(i) = imageset.make_key(p.Results.TestKeys(kk), p.Results.FileKeys(imagePairs(tabTemp.ImagePairIndex(i), tabTemp.StimTestType(i))));
        else
            if tabTemp.StimTestType(i) == 1
                StimTestKey(i) = tabTemp.Stim1Key(i);
            elseif tabTemp.StimTestType(i) == 2
                StimTestKey(i) = tabTemp.Stim2Key(i);
            else
                error('Bad test key!');
            end
        end
    end
    tabTemp.StimTestKey = StimTestKey;
    
    % base value
    tabTemp.Base = generateColumn(nTrials, 100);

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

