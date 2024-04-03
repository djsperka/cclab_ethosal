function t = generateThreshBlock(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    t = [];
    
    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));
    
    p.addRequired('NumImages', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('LDispFolderKeys', @(x) ischar(x) && ~isempty(x));
    p.addRequired('RDispFolderKeys', @(x) ischar(x) && ~isempty(x));
    p.addRequired('Deltas', @(x) isnumeric(x) && isvector(x)); % TODO || (iscell(x) && all(cellfun(@(y) isnumeric(y) && isvector(y), x))));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', [1.0, 2.0], @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.25, @(x) isnumeric(x) && length(x)<3);

    p.parse(varargin{:});

    % Make a single block - Counts is the number of images to be used.

    nImages = p.Results.NumImages;
    nLeftFolderKeys = length(p.Results.LDispFolderKeys);
    nRightFolderKeys = length(p.Results.RDispFolderKeys);
    nDeltas = length(p.Results.Deltas);

    % build replacements arrays
    reps = cell(4,1);
    imageIndices = randperm(length(p.Results.FileKeys), p.Results.NumImages);
    reps{1} = p.Results.FileKeys(imageIndices);
    dfk = p.Results.LDispFolderKeys;
    reps{2} = cellstr(reshape(dfk, length(dfk), 1));
    dfk = p.Results.RDispFolderKeys;
    reps{3} = cellstr(reshape(dfk, length(dfk), 1));
    deltas = p.Results.Deltas;
    reps{4} = reshape(deltas, length(deltas), 1);

    names = {'ImageKey', 'LType', 'RType', 'Delta'};
    multiplicities = [nImages, nLeftFolderKeys, nRightFolderKeys, nDeltas];
    t = randomizeParams(multiplicities, 'VariableNames', names, 'Replacements', reps);
 
    % generate timing columns
    nTrials = height(t);
    t.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
    t.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
    t.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
    t.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
    t.SampTime = generateColumn(nTrials, p.Results.SampTime);
    t.GapTime = generateColumn(nTrials, p.Results.GapTime);
    t.RespTime = generateColumn(nTrials, p.Results.RespTime);
% 
%         % now create
%         blocks{iblock} = table(Stim1Key, Stim2Key, StimChangeWhich, StimChangeDirection, ...
%             FixationTime, MaxAcquisitionTime, FixationBreakEarlyTime, FixationBreakLateTime, SampTime, GapTime, RespTime);
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

