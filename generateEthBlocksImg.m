function trialsOrBlocks = generateEthBlocksImg(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    
    p.addRequired('NumImages', @(x) isnumeric(x) && isscalar(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('NumBlocks', 1, @(x) isnumeric(x) && x>0);

    p.parse(varargin{:});

    % build replacements arrays
    % first var is image key
    reps = cell(4,1);
    names=cell(4,1);

    imageIndices = randperm(length(p.Results.FileKeys), p.Results.NumImages);
    reps{1} = reshape(p.Results.FileKeys(imageIndices), p.Results.NumImages, 1);
    names{1} = 'ImageKey';

    % salience
    reps{2}={'H';'L'};
    names{2} = 'Folder1Key';

    % salience
    reps{3}={'H';'L'};
    names{3} = 'Folder2Key';

    % change/nochange test
    StimTestType = 1;
    reps{4} = [0;StimTestType];
    names{4} = 'StimChangeType';

    % Multiplicites removed; it is inferred from the shape of reps.
    %multiplicities = [p.Results.NumImages, 2, 2, 2, length(p.Results.Deltas)];
    trialsOrBlocks = randomizeParams('VariableNames', names, 'Replacements', reps);
    nTrials = height(trialsOrBlocks);

    % StimKeys
    trialsOrBlocks.Stim1Key = imageset.make_keys(trialsOrBlocks.Folder1Key, trialsOrBlocks.ImageKey);
    trialsOrBlocks.Stim2Key = imageset.make_keys(trialsOrBlocks.Folder2Key, trialsOrBlocks.ImageKey);

    % StimTestType
    trialsOrBlocks.StimTestType = ones(nTrials, 1) * StimTestType;

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

    % 
    % % checkif we need to break into blocks
    % if p.Results.NumBlocks > 1
    %     % I want to make sure there's no rounding error on the last one, 
    %     % so I force the last element to be the height.
    %     endIndex = round(cumsum(ones(1, p.Results.NumBlocks)/p.Results.NumBlocks) * nTrials);
    %     endIndex(p.Results.NumBlocks) = nTrials;    
    %     blocks = cell(p.Results.NumBlocks, 1);
    %     lastEnd = 0;
    %     for iblock=1:p.Results.NumBlocks
    %         blocks{iblock} = trialsOrBlocks(lastEnd+1:endIndex(iblock), :);
    %         fprintf('Block %d has %d elements\n', iblock, height(blocks{iblock}));
    %         lastEnd = endIndex(iblock);
    %     end
    %     trialsOrBlocks = blocks;
    % end



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

