function t = generateThreshBlockGabor(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    
    p.addRequired('NumImages', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('Deltas', @(x) isnumeric(x) && isvector(x)); % TODO || (iscell(x) && all(cellfun(@(y) isnumeric(y) && isvector(y), x))));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);

    p.parse(varargin{:});

    % build replacements arrays
    % first var is image key
    reps = cell(5,1);
    names=cell(1,5);

    imageIndices = randperm(length(p.Results.FileKeys), p.Results.NumImages);
    reps{1} = reshape(p.Results.FileKeys(imageIndices), p.Results.NumImages, 1);
    names{1} = 'ImageKey';

    % salience
    reps{2}={'H';'L'};
    names{2} = 'FolderKey';

    % lr test
    reps{3} = [1;2];
    names{3} = 'StimTestType';

    % ori of test gabor
    reps{4} = [0;90];
    names{4} = 'TestOri';

    % contrasts
    reps{5} = reshape(p.Results.Deltas, length(p.Results.Deltas), 1);
    names{5} = 'Delta';
    
    multiplicities = [p.Results.NumImages, 2, 2, 2, length(p.Results.Deltas)];
    t = randomizeParams(multiplicities, 'VariableNames', names, 'Replacements', reps);
 
    % StimKeys
    t.Stim1Key = imageset.make_keys(t.FolderKey, t.ImageKey);
    t.Stim2Key = t.Stim1Key;
    t.Stim1Key(t.StimTestType==2) = {'BKGD'};
    t.Stim2Key(t.StimTestType==1) = {'BKGD'};
    
    % StimChangeType
    nTrials = height(t);
    t.StimChangeType = zeros(nTrials, 1);
    t.StimChangeType(t.StimTestType==1 & t.TestOri==90) = 1;
    t.StimChangeType(t.StimTestType==2 & t.TestOri==90) = 2;
    
    % base value
    t.Base = generateColumn(nTrials, 100);

    % etc
    t.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
    t.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
    t.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
    t.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
    t.SampTime = generateColumn(nTrials, p.Results.SampTime);
    t.GapTime = generateColumn(nTrials, p.Results.GapTime);
    t.RespTime = generateColumn(nTrials, p.Results.RespTime);
    t.TestTime = generateColumn(nTrials, p.Results.TestTime);

    % results
    t.Started = false(nTrials, 1);
    t.trialIndex = zeros(nTrials, 1);
    t.Aon = generateColumn(nTrials, -1);
    t.Aoff = generateColumn(nTrials, -1);
    t.Bon = generateColumn(nTrials, -1);
    t.Boff = generateColumn(nTrials, -1);
    t.tResp = generateColumn(nTrials, -1);
    t.iResp = -1*ones(nTrials, 1);


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

