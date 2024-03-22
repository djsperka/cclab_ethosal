function [blocks] = generateEthBlocks(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    blocks = [];
    
    p=inputParser;
    p.addRequired('FileKeys', @(x) iscellstr(x));
    
    % LRNCounts is a 3xN matrix. First, second, third rows are change-left, -right,
    % -none.
    p.addRequired('LRNCounts', @(x) isnumeric(x) && size(x, 1)==3);
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', [1.0, 2.0], @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 1.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 1.0, @(x) isnumeric(x) && length(x)<3);

    p.parse(varargin{:});
    
    % for each image selected, there are 4 stim types. 
    % Type 1: HH
    % Type 2: HL
    % Type 3: LH
    % Type 4: LL
    nStimTypes = 4;
    
    % Each column of LRNCounts should sum to the same value = the number of
    % images we will use.
    sums = sum(p.Results.LRNCounts, 1);
    if ~all(sums==sums(1))
        error('Each column of LRNCounts input should add to the same number.');
    end
    nImages = sums(1);
    nTrials = nImages * nStimTypes;
    
    % Now choose the images. Do this by permuting the order of the images
    % (represented by their key in p.Results.FileKeys), and taking the
    % first 'nImages' images as the ones we will use. randperm does something 
    % like that. 
    % Below the var imageIndex will refer to this array, which itself has
    % indices into p.Results.FileKeys. In other words, a value of
    % 'imageIndex' has the file key
    % p.Results.FileKeys{fileKeyIndices(imageIndex))
    fileKeyIndices = randperm(length(p.Results.FileKeys), nImages);

    
    % Generate a trials struct for each COLUMN in LRNCounts
    blocks=cell(1,size(p.Results.LRNCounts, 2));
    for iblock = 1:size(p.Results.LRNCounts, 2)
    
        trialIndices = randperm(nTrials);

        % for the stim that change, randomize the direction of the change.
        lrnCounts = p.Results.LRNCounts(:,iblock);
        LChanges = ones(lrnCounts(1) * nStimTypes, 1);
        LChanges(randperm(lrnCounts(1) * nStimTypes, lrnCounts(1) * nStimTypes/2)) = -1;
        RChanges = ones(lrnCounts(2) * nStimTypes, 1);
        RChanges(randperm(lrnCounts(2) * nStimTypes, lrnCounts(2) * nStimTypes/2)) = -1;
        lCount = 0;
        rCount = 0;
    
        % initialize arrays for table. Each element of the arrays is the
        % value for that trial.
        Stim1Key=cell(nTrials, 1);
        Stim2Key=cell(nTrials, 1);
        StimChangeWhich = zeros(nTrials, 1);
        StimChangeDirection = zeros(nTrials, 1);
    
        for itrial=1:nTrials
            % imageIndex is the index into fileKeyIndices, which has indices
            % into p.Results.FileKeys. Got it?
            imageIndex = 1 + fix((trialIndices(itrial)-1)/nStimTypes);

            % stIndex is the stim type 1,2,3 or 4.
            stIndex = 1 + rem((trialIndices(itrial)-1), nStimTypes);

            switch stIndex
                case 1
                    % treat as type 1: HH
                    key1 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                    key2 = key1;
                case 2
                    % treat as type 2: HL
                    key1 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                    key2 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                case 3
                    % treat as type 3: LH
                    key1 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                    key2 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                case 4
                    % treat as type 4: LL
                    key1 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(imageIndex)});
                    key2 = key1;
                otherwise
                    error('invalid stim type'); % there should only be 4
            end   
            Stim1Key{itrial, 1} = key1;
            Stim2Key{itrial, 1} = key2;
            
            fprintf('itrial %d trialIndex %d imageIndex %d stIndex %d key1 %s key2%s\n', ...
                itrial, trialIndices(itrial), imageIndex, stIndex, key1, key2);
            
            % determine which stim changes
            if imageIndex > sum(lrnCounts(1:2))
                % NO change
                StimChangeWhich(itrial) = 0;
            elseif imageIndex > lrnCounts(1)                
                % R-change
                StimChangeWhich(itrial) = 2;
                rCount = rCount + 1;
                StimChangeDirection(itrial) = RChanges(rCount);
            else
                % L-change
                StimChangeWhich(itrial) = 1;
                lCount = lCount + 1;
                StimChangeDirection(itrial) = LChanges(lCount);
            end
            
        end


        % generate timing columns
        FixationTime = generateColumn(nTrials, p.Results.FixationTime);
        MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
        FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
        FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
        SampTime = generateColumn(nTrials, p.Results.SampTime);
        GapTime = generateColumn(nTrials, p.Results.GapTime);
        RespTime = generateColumn(nTrials, p.Results.RespTime);

        % now create
        blocks{iblock} = table(Stim1Key, Stim2Key, StimChangeWhich, StimChangeDirection, ...
            FixationTime, MaxAcquisitionTime, FixationBreakEarlyTime, FixationBreakLateTime, SampTime, GapTime, RespTime);
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

