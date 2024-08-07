function trialsOrBlocks = generateThreshBlockProcImage(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    
    p.addRequired('NumImages', @(x) isnumeric(x) && isscalar(x));
    %p.addOptional('Deltas',[0;0;10;20;30;40]);
    %p.addRequired('Deltas', @(x) isnumeric(x) && isvector(x)); % TODO || (iscell(x) && all(cellfun(@(y) isnumeric(y) && isvector(y), x))));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('NumBlocks', 1, @(x) isnumeric(x) && x>0);
    p.addOptional('Threshold', true, @(x) islogical(x));

    p.parse(varargin{:});


    if p.Results.Threshold

        % build replacements arrays
        reps = cell(4,1);
        names=cell(4,1);

        % Image key
        imageIndices = randperm(length(p.Results.FileKeys), p.Results.NumImages);
        reps{1} = reshape(p.Results.FileKeys(imageIndices), p.Results.NumImages, 1);
        names{1} = 'ImageKey';
    
        % salience - High (low) salience images in H (Q) folder
        reps{2}={'H';'Q'};
        names{2} = 'FolderKey';
    
        % lr test
        reps{3} = [1;2];
        names{3} = 'StimTestType';
    
        % % change type
        % reps{4} = [0;1];
        % names{4} = 'StimChange';
    
        % delta
        deltas = [0;0;10;20;30;40];
        reps{4} = deltas;
        names{4} = 'Delta';

        % Get the trials. This is just the randomized parameters, will need
        % to add more stuff later. 
        trialsOrBlocks = randomizeParams('VariableNames', names, 'Replacements', reps);
        nTrials = height(trialsOrBlocks);

        % StimKeys. Set them the same, then set one to 'BKGD', depending on
        % test type.
        trialsOrBlocks.Stim1Key = imageset.make_keys(trialsOrBlocks.FolderKey, trialsOrBlocks.ImageKey);
        trialsOrBlocks.Stim2Key = imageset.make_keys(trialsOrBlocks.FolderKey, trialsOrBlocks.ImageKey);

        % On a threshold block, we want a single image displayed - it will
        % be displayed on the side corresponding to the test type. Make the
        % opposite side be a background texture.
        trialsOrBlocks.Stim1Key(trialsOrBlocks.StimTestType==2) = {'BKGD'};
        trialsOrBlocks.Stim2Key(trialsOrBlocks.StimTestType==1) = {'BKGD'};
        
        % for using +- 10, +-20
        % mH=containers.Map([-20,-10,0,10,20],{'F','G','H','I','J'});
        % mQ=containers.Map([-20,-10,0,10,20],{'O','P','Q','R','S'});
        % lzH = strcmp(trialsOrBlocks.FolderKey, 'H');
        % lzQ = strcmp(trialsOrBlocks.FolderKey, 'Q');
        mH=containers.Map([0,10,20,30,40],{'H','I','J','K','L'});
        mQ=containers.Map([0,10,20,30,40],{'Q','R','S','T','U'});
        lzH = strcmp(trialsOrBlocks.FolderKey, 'H');
        lzQ = strcmp(trialsOrBlocks.FolderKey, 'Q');
        z = cell(height(trialsOrBlocks), 1);
        z(lzH) = arrayfun(@(x) {mH(x)}, trialsOrBlocks.Delta(lzH));
        z(lzQ) = arrayfun(@(x) {mQ(x)}, trialsOrBlocks.Delta(lzQ));
        trialsOrBlocks.StimTestKey = imageset.make_keys(z, trialsOrBlocks.ImageKey);

        % StimChange - does the stim change on this trial?
        trialsOrBlocks.StimChange = trialsOrBlocks.Delta>0;

        % StimChangeType
        trialsOrBlocks.StimChangeType = zeros(nTrials, 1);
        trialsOrBlocks.StimChangeType(trialsOrBlocks.StimTestType==1 & trialsOrBlocks.StimChange) = 1;
        trialsOrBlocks.StimChangeType(trialsOrBlocks.StimTestType==2 & trialsOrBlocks.StimChange) = 2;
    else
        error('Not implemented Threshold=false')
    end


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

