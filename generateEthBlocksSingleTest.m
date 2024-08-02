function [trialsOrBlocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(varargin)
%generateEthBlocksSingleTest - Generate blocks for eth salience, using just
%a single second stim.
%   Detailed explanation goes here

    trialsOrBlocks = [];
    inputArgs = varargin;
    parsedResults = [];
    
    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));
    
    % ImageCounts can be 4xN or 3xN. 
    % Original usage was 4xN, where the rows represent the number of images
    % used for change-left, change-right, nochange-left, nochange-right,
    % respectively.
    % If ImageCounts is 3xN, then the rows represent images used for
    % change-left, change-right, and nochange. This is for expts where two
    % TEST images are shown, and so while change-left and change-right are
    % distinct, nochange trials have no left- or right- type, because two
    % images are shown. 

    p.addRequired('ImageCounts', @(x) isnumeric(x) && (size(x, 1)==4 || size(x,1)==3));
    p.addRequired('BaseContrast', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('Delta', @(x) isnumeric(x) && isscalar(x));
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

    doStimTestKey = false;
    if length(p.Results.TestKeys) > 0
        if length(p.Results.TestKeys) == length(p.Results.FolderKeys)
            doStimTestKey = true;
        else
            error('TestKeys should be same length as FolderKeys');
        end
    end


    % for each image selected, there are 4 stim types. 
    % Type 1: HH
    % Type 2: HL
    % Type 3: LH
    % Type 4: LL
    nStimTypes = 4;
    
    % Each column of LRNCounts should sum to the same value = the number of
    % images we will use.
    sums = sum(p.Results.ImageCounts, 1);
    if ~all(sums==sums(1))
        warning('The columns of ImageCounts do not add to the same number.');
    end
    nImages = sums(1);
    nTrials = nImages * nStimTypes;

    varNames = {
        'StimPairType'          ,
        'Stim1Key'              ,
        'Stim2Key'              ,
        'StimTestKey'           ,
        'AttendSide'            ,
        'StimChangeType'        ,
        'StimTestType'          ,
        'Base'                  ,
        'Delta'                 ,
        'FixationTime'          ,
        'MaxAcquisitionTime'    ,
        'FixationBreakEarlyTime',
        'FixationBreakLateTime' ,
        'SampTime'              ,
        'GapTime'               ,
        'TestTime'              ,
        'RespTime'              ,
        'Started'               ,
        'trialIndex'            ,
        'tAon'                  ,
        'tAoff'                 ,
        'tBon'                  ,
        'tBoff'                 ,
        'tResp'                 ,
        'iResp'                 ,
        };

    varTypes = {'string','string','string','string','int32','int32','int32','double','double','double','double','double','double','double','double','double','double','logical','int32','double','double','double','double','double','int32'};


    % If there are 4 rows, expecting single-test-type trials. 
    if size(p.Results.ImageCounts, 1) == 4
        doSingleTestTypeTrials = true;
    else
        doSingleTestTypeTrials = false;
    end

    % Generate a trials struct (i.e. a block) for each COLUMN in
    % ImageCounts. The images are randomized, but the order they are sorted
    % into is reused on each block. 

    trialsOrBlocks=cell(1,size(p.Results.ImageCounts, 2));

    for iblock = 1:size(p.Results.ImageCounts, 2)

        % divvy up the images
        fkeyInd = randperm(length(p.Results.FileKeys), nImages);

        t=table('Size', [nTrials, length(varNames)], 'VariableNames', varNames, 'VariableTypes', varTypes);

        imageCountsThisBlock = p.Results.ImageCounts(:,iblock);
        for igroup=1:size(p.Results.ImageCounts, 1)
            attendSideThisBlock = 0;    
            imageIndStart = sum(imageCountsThisBlock(1:igroup-1))+1;
            imageIndEnd = sum(imageCountsThisBlock(1:igroup));

            if doSingleTestTypeTrials
                switch igroup
                    case 1
                        % Left-change trials.
                        stimChangeTypeThisGroup = 1;
                        stimTestTypeThisGroup = 1;
                    case 2
                        % Right-change trials.
                        stimChangeTypeThisGroup = 2;
                        stimTestTypeThisGroup = 2;
                    case 3
                        % Left-nochange trials.
                        stimChangeTypeThisGroup = 0;
                        stimTestTypeThisGroup = 1;
                    case 4
                        % Right-nochange trials.
                        stimChangeTypeThisGroup = 0;
                        stimTestTypeThisGroup = 2;
                    otherwise
                        error('too many groups for single-test-image type trials (expect 4)!');
                end
            else
                switch igroup
                    case 1
                        % Left-change trials.
                        stimChangeTypeThisGroup = 1;
                        stimTestTypeThisGroup = 1;
                    case 2
                        % Right-change trials.
                        stimChangeTypeThisGroup = 2;
                        stimTestTypeThisGroup = 2;
                    case 3
                        % Nochange trials.
                        stimChangeTypeThisGroup = 0;
                        stimTestTypeThisGroup = 0;
                    otherwise
                        error('too many groups for dual-test-image type trials (expect 3)!');
                end                        
            end                

            % ifkeyInd is an index into fkeyInd, which is itself an array 
            % returned from randperm. So, the input list of file keys  
            % (p.Results.FileKeys is the list of file base names, without 
            % their folder key/letter)
            % starting point for image index - we skip over all previously
            % used images
            for ifkeyInd = imageIndStart:imageIndEnd

                % HH
                itrial = (ifkeyInd-1)*4 + 1;
                imageKey = p.Results.FileKeys{fkeyInd(ifkeyInd)};
                t.StimPairType(itrial) = 'HH';
                t.Stim1Key(itrial) = imageset.make_key(p.Results.FolderKeys{1}, imageKey);
                t.Stim2Key(itrial) = t.Stim1Key(itrial);
                t.AttendSide(itrial) = attendSideThisBlock;
                t.StimChangeType(itrial) = stimChangeTypeThisGroup;
                t.StimTestType(itrial) = stimTestTypeThisGroup;
                t.Base(itrial) = p.Results.BaseContrast;
                t.Delta(itrial) = p.Results.Delta;

                if doStimTestKey
                    t.StimTestKey(itrial) = getStimTestKey(t.StimPairType(itrial), p.Results.FolderKeys, p.Results.TestKeys, stimTestTypeThisGroup, stimChangeTypeThisGroup, imageKey);
                else
                    t.StimTestKey(itrial) = "N/A";
                end

                % HL
                itrial = (ifkeyInd-1)*4 + 2;
                imageKey = p.Results.FileKeys{fkeyInd(ifkeyInd)};
                t.StimPairType(itrial) = 'HL';
                t.Stim1Key(itrial) = imageset.make_key(p.Results.FolderKeys{1}, imageKey);
                t.Stim2Key(itrial) = imageset.make_key(p.Results.FolderKeys{2}, imageKey);
                t.AttendSide(itrial) = attendSideThisBlock;
                t.StimChangeType(itrial) = stimChangeTypeThisGroup;
                t.StimTestType(itrial) = stimTestTypeThisGroup;
                t.Base(itrial) = p.Results.BaseContrast;
                t.Delta(itrial) = p.Results.Delta;
    
                if doStimTestKey
                    t.StimTestKey(itrial) = getStimTestKey(t.StimPairType(itrial), p.Results.FolderKeys, p.Results.TestKeys, stimTestTypeThisGroup, stimChangeTypeThisGroup, imageKey);
                else
                    t.StimTestKey(itrial) = "N/A";
                end

                % LH
                itrial = (ifkeyInd-1)*4 + 3;
                imageKey = p.Results.FileKeys{fkeyInd(ifkeyInd)};
                t.StimPairType(itrial) = 'LH';
                t.Stim1Key(itrial) = imageset.make_key(p.Results.FolderKeys{2}, imageKey);
                t.Stim2Key(itrial) = imageset.make_key(p.Results.FolderKeys{1}, imageKey);
                t.AttendSide(itrial) = attendSideThisBlock;
                t.StimChangeType(itrial) = stimChangeTypeThisGroup;
                t.StimTestType(itrial) = stimTestTypeThisGroup;
                t.Base(itrial) = p.Results.BaseContrast;
                t.Delta(itrial) = p.Results.Delta;
    
                if doStimTestKey
                    t.StimTestKey(itrial) = getStimTestKey(t.StimPairType(itrial), p.Results.FolderKeys, p.Results.TestKeys, stimTestTypeThisGroup, stimChangeTypeThisGroup, imageKey);
                else
                    t.StimTestKey(itrial) = "N/A";
                end

                % LL
                itrial = (ifkeyInd-1)*4 + 4;
                imageKey = p.Results.FileKeys{fkeyInd(ifkeyInd)};
                t.StimPairType(itrial) = 'LL';
                t.Stim1Key(itrial) = imageset.make_key(p.Results.FolderKeys{2}, imageKey);
                t.Stim2Key(itrial) = imageset.make_key(p.Results.FolderKeys{2}, imageKey);
                t.AttendSide(itrial) = attendSideThisBlock;
                t.StimChangeType(itrial) = stimChangeTypeThisGroup;
                t.StimTestType(itrial) = stimTestTypeThisGroup;
                t.Base(itrial) = p.Results.BaseContrast;
                t.Delta(itrial) = p.Results.Delta;

                if doStimTestKey
                    t.StimTestKey(itrial) = getStimTestKey(t.StimPairType(itrial), p.Results.FolderKeys, p.Results.TestKeys, stimTestTypeThisGroup, stimChangeTypeThisGroup, imageKey);
                else
                    t.StimTestKey(itrial) = "N/A";
                end
            end
        end

        % finish initialization
        t.Base = generateColumn(nTrials, p.Results.BaseContrast);
        t.FixationTime = generateColumn(nTrials, p.Results.FixationTime);
        t.MaxAcquisitionTime = generateColumn(nTrials, p.Results.MaxAcquisitionTime);
        t.FixationBreakEarlyTime = generateColumn(nTrials, p.Results.FixationBreakEarlyTime);
        t.FixationBreakLateTime = generateColumn(nTrials, p.Results.FixationBreakLateTime);
        t.SampTime = generateColumn(nTrials, p.Results.SampTime);
        t.GapTime = generateColumn(nTrials, p.Results.GapTime);
        t.TestTime = generateColumn(nTrials, p.Results.TestTime);
        t.RespTime = generateColumn(nTrials, p.Results.RespTime);
        t.tResp = generateColumn(nTrials, -1);
        t.Started(:) = false;

        % randomize order of rows
        t = t(randperm(height(t)), :);

        % checkif we need to break into blocks
        if p.Results.NumBlocks > 1
            % I want to make sure there's no rounding error on the last one, 
            % so I force the last element to be the height.
            endIndex = round(cumsum(ones(1, p.Results.NumBlocks)/p.Results.NumBlocks) * nTrials);
            endIndex(p.Results.NumBlocks) = nTrials;    
            blocks = cell(p.Results.NumBlocks, 1);
            lastEnd = 0;
            for ibl=1:p.Results.NumBlocks
                blocks{ibl} = t(lastEnd+1:endIndex(ibl), :);
                fprintf('Block %d has %d elements\n', ibl, height(blocks{ibl}));
                lastEnd = endIndex(ibl);
            end
            trialsOrBlocks = blocks;
        else
            trialsOrBlocks = t;
        end

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

function [skey] = getStimTestKey(stimPairType, folderKeys, testKeys, stimTestType, stimChangeType, fkey)
    c=char(stimPairType);
    if stimChangeType~=1 && stimChangeType~=2
        skey = imageset.make_key(folderKeys{c(stimTestType)=='HL'}, fkey);
    else
        skey = imageset.make_key(testKeys{c(stimTestType)=='HL'}, fkey);
    end
end