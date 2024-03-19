function [trials] = generateEthBlocks(varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    trials = [];
    
    p=inputParser;
    p.addRequired('FileKeys', @(x) iscellstr(x));
    p.addRequired('LNRCounts', @(x) isvector(x) && length(x)==3);
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.parse(varargin{:});
    
    fprintf('%d keys, counts %d %d %d sum %d\n', length(p.Results.FileKeys), p.Results.LNRCounts(1), p.Results.LNRCounts(2), p.Results.LNRCounts(3), sum(p.Results.LNRCounts));

    % for each image selected, there are 4 stim types. 
    % Type 1: HH
    % Type 2: HL
    % Type 3: LH
    % Type 4: LL
    numStimTypes = 4;
    
    % select images to use. 
    % The LNRCounts array should be 1x3, where the 3 columns are the number
    % of Left-change, NO-change, Right-change images. The sum of those
    % values is the total number of images to be used. 
    % So, fileKeyIndices is a permutation of  1:(number of images).
    % We multiply by 4 (the number of stim types - HH, HL, LH, LL), so the
    % numbers 1-4 represent the image p.Results.FileKeys{1} in type 1-4.
    % The numbers 5-8 are image key p.Results.FileKeys{2} in type 1-4, and
    % so on. 
    
    % fileKeyIndices is the same length as sum(LeftChange + NoChange +
    % RightChange) - same as total number of images (counting the H and L 
    % as one image) to be used. 
    %
    % trialIndices is length (number of images) * 4, where 4 is the number
    % of different stim types (HH, HL, LH, LL). 
    % 
    % To determine the image for a trial, take the value of
    % trialIndices(itrial), and do 1+trialIndices(itrial)/4 (int division)
    
    fileKeyIndices = randperm(length(p.Results.FileKeys), sum(p.Results.LNRCounts));
    trialIndices = randperm(length(fileKeyIndices) * numStimTypes);
    
    % for the stim that change, randomize the direction of the change.
    LChangeDirections = ones(p.Results.LNRCounts(1) * numStimTypes, 1);
    LChangeDirections(randperm(p.Results.LNRCounts(1) * numStimTypes, p.Results.LNRCounts(1) * numStimTypes/2)) = -1;
    RChangeDirections = ones(p.Results.LNRCounts(3) * numStimTypes, 1);
    RChangeDirections(randperm(p.Results.LNRCounts(3) * numStimTypes, p.Results.LNRCounts(3) * numStimTypes/2)) = -1;
    lCount = 0;
    rCount = 0;
    
    Stim1Key=cell(length(trialIndices), 1);
    Stim2Key=cell(length(trialIndices), 1);
    StimChange = zeros(length(trialIndices), 1);
    StimChangeDirection = zeros(length(trialIndices), 1);
    
    for itrial=1:length(trialIndices)
        fileKeyIndex = 1 + fix((trialIndices(itrial)-1)/numStimTypes);
        stIndex = 1 + rem((trialIndices(itrial)-1), numStimTypes);
        fprintf('itrial %d trialInd %d imageInd %d stInd %d key \n', itrial, trialIndices(itrial), fileKeyIndex, stIndex);
        % , p.Results.FileKeys{fileKeyIndices(fileKeyIndex)}
        switch stIndex
            case 1
                % treat as type 1: HH
                key1 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
                key2 = key1;
            case 2
                % treat as type 2: HL
                key1 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
                key2 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
            case 3
                % treat as type 3: LH
                key1 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
                key2 = imageset.make_key(p.Results.FolderKeys{1}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
            case 4
                % treat as type 4: LL
                key1 = imageset.make_key(p.Results.FolderKeys{2}, p.Results.FileKeys{fileKeyIndices(fileKeyIndex)});
                key2 = key1;
            otherwise
                error('invalid stim type'); % there should only be 4
        end   
        Stim1Key{itrial, 1} = key1;
        Stim2Key{itrial, 1} = key2;
        
        % determine which stim changes
        if fileKeyIndex > sum(p.Results.LNRCounts(1:2))
            % R-change
            StimChange(itrial) = 2;
            rCount = rCount + 1;
            StimChangeDirection(itrial) = RChangeDirections(rCount);
        elseif fileKeyIndex > p.Results.LNRCounts(1)
            % NO change
            StimChange(itrial) = 0;
        else
            % L-change
            StimChange(itrial) = 1;
            lCount = lCount + 1;
            StimChangeDirection(itrial) = LChangeDirections(lCount);
        end
                
    end     
    trials = table(Stim1Key, Stim2Key, StimChange, StimChangeDirection);
    
end

