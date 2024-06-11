function [blocks, inputArgs, parsedResults] = generateEthBlocksSingleTest(varargin)
%generateEthBlocksSingleTest - Generate blocks for eth salience, using just
%a single second stim.
%   Detailed explanation goes here

    blocks = [];
    inputArgs = varargin;
    parsedResults = [];
    
    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));
    
    % LRNCounts is a 4xN matrix. First, second, third rows are change-left, 
    % change-right, nochange-left, nochange-right.
    p.addRequired('LRNCounts', @(x) isnumeric(x) && size(x, 1)==4);
    p.addRequired('BaseContrast', @(x) isnumeric(x) && isscalar(x));
    p.addRequired('Delta', @(x) isnumeric(x) && isscalar(x));
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);

    p.parse(varargin{:});
    parsedResults = p.Results;

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
    nImages = sums(1)
    nTrials = nImages * nStimTypes;

    % divvy up the images
    fkeyInd = randperm(length(p.Results.FileKeys), nImages);

    varNames = {
        'StimPairType'          ,
        'Stim1Key'              ,
        'Stim2Key'              ,
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

    varTypes = {'string','string','string','int32','int32','int32','double','double','double','double','double','double','double','double','double','double','logical','int32','double','double','double','double','double','int32'};


    % Generate a trials struct for each COLUMN in LRNCounts
    blocks=cell(1,size(p.Results.LRNCounts, 2));

    for iblock = 1:size(p.Results.LRNCounts, 2)

        switch iblock
            case 1
                % left
                attendSideThisBlock = 1;
            case 2
                % right
                attendSideThisBlock = 2;
            case 3
                % none
                attendSideThisBlock = 0;
            otherwise
                error('I do not know what to do with more than 3 blocks.')
        end
        t=table('Size', [nTrials, length(varNames)], 'VariableNames', varNames, 'VariableTypes', varTypes);

        lrnCountsThisBlock = p.Results.LRNCounts(:,iblock);
        for igroup=1:4
            nThisGroup = lrnCountsThisBlock(igroup);
            imageIndStart = sum(lrnCountsThisBlock(1:igroup-1))+1;
            imageIndEnd = sum(lrnCountsThisBlock(1:igroup));
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
                    error('too many groups!');
            end

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
        blocks{iblock} = t(randperm(height(t)), :);

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
