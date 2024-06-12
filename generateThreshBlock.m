function t = generateThreshBlock(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    t = [];
    
    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));
    
    p.addRequired('NumImages', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('FolderKeys', @(x) ischar(x) && ~isempty(x));
    p.addRequired('Base', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('Deltas', @(x) isnumeric(x) && isvector(x)); % TODO || (iscell(x) && all(cellfun(@(y) isnumeric(y) && isvector(y), x))));
    p.addRequired('ChangeType', @(x) isnumeric(x) && isscalar(x) && ismember(x,[1,2]));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);

    p.parse(varargin{:});

    % Make a single block - Counts is the number of images to be used.

    nImages = p.Results.NumImages;
    if p.Results.ChangeType == 1
        RFolderKeys = '*';
        LFolderKeys = p.Results.FolderKeys;
    else
        LFolderKeys = '*';
        RFolderKeys = p.Results.FolderKeys;
    end        
    nLeftFolderKeys = length(LFolderKeys);
    nRightFolderKeys = length(RFolderKeys);
    nDeltas = length(p.Results.Deltas);

    % build replacements arrays
    reps = cell(4,1);
    imageIndices = randperm(length(p.Results.FileKeys), p.Results.NumImages);
    reps{1} = p.Results.FileKeys(imageIndices);
    dfk = LFolderKeys;
    reps{2} = cellstr(reshape(dfk, length(dfk), 1));
    dfk = RFolderKeys;
    reps{3} = cellstr(reshape(dfk, length(dfk), 1));
    deltas = p.Results.Deltas;
    reps{4} = reshape(deltas, length(deltas), 1);

    names = {'ImageKey', 'LType', 'RType', 'Delta'};
    multiplicities = [nImages, nLeftFolderKeys, nRightFolderKeys, nDeltas];
    t = randomizeParams(multiplicities, 'VariableNames', names, 'Replacements', reps);
 
    % generate timing and stimulus columns
    t.Stim1Key=imageset.make_keys(t.LType, t.ImageKey);
    t.Stim2Key=imageset.make_keys(t.RType, t.ImageKey);
    nTrials = height(t);

    % StimPairType - needed for     etholog, but not really.
    t.StimPairType = char(strcat(t.LType, t.RType));

    % base value
    t.Base = generateColumn(nTrials, p.Results.Base);

    % Fix change types when delta is zero.
    t.StimChangeType = generateColumn(nTrials, p.Results.ChangeType);
    t.StimChangeType(t.Delta == 0) = 0;

    t.StimTestType = generateColumn(nTrials, p.Results.ChangeType);
    t.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
    t.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
    t.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
    t.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
    t.SampTime = generateColumn(nTrials, p.Results.SampTime);
    t.GapTime = generateColumn(nTrials, p.Results.GapTime);
    t.RespTime = generateColumn(nTrials, p.Results.RespTime);
    t.TestTime = generateColumn(nTrials, p.Results.TestTime);

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

