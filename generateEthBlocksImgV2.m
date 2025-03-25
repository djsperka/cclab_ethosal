function [allTrialSets, inputArgs, parsedResults, myname]  = generateEthBlocksImgV2(varargin)
%generateEthBlocksImgV2 Generate trial sets for ethological salience expt
%'ethologV2'.
%   [blocks,inputArgs,parsedResults,scriptName] = ...
%          generateEthBlocksImgV2(img.BalancedFileKeys, ...
%                                 [20,30,0;20,0,30;30,0,0], Base=4, NumBlocks=2);

    myname = mfilename;

    p=inputParser;  
    p.addRequired('FileKeys', @(x) iscellstr(x));    

    % For regular trials this is the number of pairs. 
    % For threshold trials, this is the number of images to use.
    % 10/3/24 djs Num can be a vector of up to 3 elements. The three
    % elements are the number of pairs for "both", "left", and "right". If
    % any of them is zero then no trials of that type will be generated. 

    p.addRequired('Num', @(x) isnumeric(x) && size(x, 2)<=3);
    p.addOptional('FolderKeys', {'H'; 'L'},  @(x) iscellstr(x));
    p.addOptional('MixFolderColumns', false, @(x) islogical(x));
    p.addOptional('TestKeys', [],  @(x) iscellstr(x));
    p.addOptional('FixationTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('MaxAcquisitionTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakEarlyTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('FixationBreakLateTime', 0.5, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('SampTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('TestTime', 0.4, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('RespTime', 2.0, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('GapTime', 0.2, @(x) isnumeric(x) && length(x)<3);
    p.addOptional('NumBlocks', 1, @(x) isscalar(x) && x>0);

    p.addOptional('FlipPair', false, @(x) islogical(x));  % image pairs are same image, one is flipped.
    p.addOptional('Threshold', false, @(x) islogical(x));
    p.addOptional('CueSide', 0, @(x) isnumeric(x) && all(ismember(x,[0,1,2])));
    p.addOptional('Base', 5, @(x) isnumeric(x));

    p.parse(varargin{:});
    parsedResults = p.Results;
    inputArgs = varargin;

    % Verify that shape of CueSide is good
    if ~isscalar(p.Results.CueSide)
        assert(length(p.Results.CueSide) == size(p.Results.Num, 1), 'CueSide must be scalar or have one value per row of Num');
    end

    % make convenience vars and check size of TestKeys/FolderKeys
    FolderKeys = p.Results.FolderKeys;
    if isempty(p.Results.TestKeys)
        TestKeys = FolderKeys;
    else
        TestKeys = p.Results.TestKeys;
    end
    FileKeys = p.Results.FileKeys;
    nFileKeys = length(FileKeys);
    if size(TestKeys) ~= size(FolderKeys)
        error('FolderKeys and TestKeys must be same size');
    end

    %% Regular trials - not threshold

    % The number of trials will be 16*nPairs
    % where 16 = (left folder key)*(right folder
    % key)*(StimTestType=1,2)*(StimChangeTF=0,1)

    allTrialSets = cell(size(p.Results.Num, 1), 1);
    if ~p.Results.Threshold

        tabTemp = [];

        % If there are multiple rows in p.Results.Num, then each row
        % denotes a block. Each block should use the same set of image
        % pairs, however, so multiple blocks can be generated here. 
        % 
        % The sum along each row of p.Results.Num must be the same! 

        numSums = sum(p.Results.Num, 2);
        if ~all(numSums(1)==numSums)
            warning('All rows of Num do not add up to same number.');
        end
        

        % Set up image pairs. The array 'imagePairs' has two columns, and
        % the one row for each image pair needed - that's the same as the
        % sum across each row of p.Results.Num.

        allPairs = max(numSums);
        if ~p.Results.FlipPair
            imagePairs=reshape(randperm(nFileKeys, allPairs*2), [allPairs,2]);
        else
            imagePairsTmp = randperm(nFileKeys, allPairs);
            imagePairs = vertcat(imagePairsTmp, imagePairsTmp)';
        end

        for itrialset = 1 : size(p.Results.Num, 1)

            C = cumsum(p.Results.Num(itrialset, :));
            thisSetNums = p.Results.Num(itrialset, :);
            thisSetTable = [];

            if isscalar(p.Results.CueSide)
                cueSideThisTrialSet = p.Results.CueSide;
            else
                cueSideThisTrialSet = p.Results.CueSide(itrialset); % This was verified above!
            end
            for i = 1:length(thisSetNums)
    
                if thisSetNums(i) > 0
    
                    %replacements = cell(7,1);
                    %columnNames=cell(7,1);
                    replacements = {};
                    columnNames = {};


                    % Select the images that will be used
                    rep = (C(i)-thisSetNums(i)+1 : C(i))';
                    replacements{1} = rep;
                    columnNames{1} = 'ImagePairIndex';

                    % input FolderKeys: 
                    % Columns = groups of images
                    % Rows = salience within group
                    %
                    % {'H', 'F', 'N';
                    %  'L', 'f', 'n'}
                    % 
                    % Here there are three groups of images. One group has
                    % folder keys 'H' and 'L', another 'F'&'f', and the
                    % last 'N'&'n'. The first row, 'H', 'F', 'N' should be
                    % same salience (all high salience here), and the
                    % second row would be the low salience counterparts. 
                    % 
                    % Within a column, an image '1.bmp' is taken from the
                    % same starting point, but is processed differently. 
                    %
                    % Images for a trial are taken from the same column of
                    % the FolderKeys array, unless 'MixFolderColumns' is
                    % true. In the example above, if 'MixFolderColumns' is
                    % false, the default, then the images for a given trial
                    % are taken from the same column - i.e. 'H'&'L' are
                    % mixed in a trial, but they never appear with any of
                    % the other image folders 'FfNn'. If 'MixFolderColumns'
                    % is true, there can be any combination of the columns
                    % in a trial - e.g. 'H'&'f', etc. When
                    % 'MixFolderColumns' is true, the sciHH, etc values are
                    % set regardless of column (but their salience is still
                    % assumed to be HIGH for the first row andLOW for the
                    % second).
               
                    if p.Results.MixFolderColumns
                        replacements{end+1} = (1:size(p.Results.FolderKeys,2))';
                        columnNames{end+1} = 'Folder1KeyColumn';
                        replacements{end+1} = (1:size(p.Results.FolderKeys,2))';
                        columnNames{end+1} = 'Folder2KeyColumn';
                    else
                        replacements{end+1} = (1:size(p.Results.FolderKeys,2))';
                        columnNames{end+1} = 'FolderKeyColumn';
                    end

                    replacements{end+1} = (1:size(p.Results.FolderKeys,1))';
                    columnNames{end+1} = 'Folder1KeyRow';

                    replacements{end+1} = (1:size(p.Results.FolderKeys,1))';
                    columnNames{end+1} = 'Folder2KeyRow';

                
                    % TestType? L=1, R=2
                    % First element of thisBlockNums is the number that will
                    % have both left&right test. Second element is left-only,
                    % third element is righ-only. Remember that TestType==1
                    % means left test, TestType==2 means right test.
    
                    switch (i)
                        case 1
                            replacements{end+1}=[1;2];
                        case 2
                            replacements{end+1}=[1];
                        case 3
                            replacements{end+1}=[2];
                    end        
                    columnNames{end+1} = 'StimTestType';
                
                    % change/nochange test
                    replacements{end+1} = [0;1];
                    columnNames{end+1} = 'StimChangeTF';
                
                    % Base value (for rotations)
                    replacements{end+1} = p.Results.Base;
                    columnNames{end+1} = 'Base';
                
                
                    % This generates trials with things distributed over the elements of
                    % names/reps.
                    tab1 = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);
                    nTrials = height(tab1);
                
                
                    % Now make File1Key and File2Key
                    tab1.File1Key = FileKeys(imagePairs(tab1.ImagePairIndex,1));

                    tab1.File2Key = FileKeys(imagePairs(tab1.ImagePairIndex,2));

                    % Now make Folder1Key and Folder2Key
                    if ~p.Results.MixFolderColumns
                        tab1.Folder1KeyColumn = tab1.FolderKeyColumn;
                        tab1.Folder2KeyColumn = tab1.FolderKeyColumn;
                    end
                    tab1.Folder1Key = FolderKeys(sub2ind(size(FolderKeys), tab1.Folder1KeyRow(:), tab1.Folder1KeyColumn(:)));
                    tab1.Folder2Key = FolderKeys(sub2ind(size(FolderKeys), tab1.Folder2KeyRow(:), tab1.Folder2KeyColumn(:)));

                    % StimA1Key and StimA2Key
                    tab1.StimA1Key = imageset.make_keys(tab1.Folder1Key, tab1.File1Key);
                    tab1.StimA2Key = imageset.make_keys(tab1.Folder2Key, tab1.File2Key);
                
                    % StimChangeType
                    tab1.StimChangeType = tab1.StimChangeTF.*tab1.StimTestType;
                
                    % Initial orientation
                    if ~p.Results.FlipPair
                        tab1.Stim1Ori = (2*randi([0 1],nTrials, 1))-1;
                        tab1.Stim2Ori = (2*randi([0 1],nTrials, 1))-1;
                    else
                        tab1.Stim1Ori = (2*randi([0 1],nTrials, 1))-1;
                        tab1.Stim2Ori = -1*tab1.Stim1Ori;
                    end
                
                    %% Now make B stim keys. 
                    % First, initialize all of them to 'BKGD'. 
                    StimB1Key=cell(size(tab1.StimA1Key));
                    [StimB1Key{:}] = deal('BKGD');
                    StimB2Key=cell(size(tab1.StimA1Key));
                    [StimB2Key{:}] = deal('BKGD');
                
                    % logical arrays for trials where stim1/Stim2 do not change
                    ncL1 = tab1.StimTestType==1 & ~tab1.StimChangeTF;
                    ncL2 = tab1.StimTestType==2 & ~tab1.StimChangeTF;
                
                    % For no-change trials, the B key is same as A key.
                    StimB1Key(ncL1) = tab1.StimA1Key(ncL1);
                    StimB2Key(ncL2) = tab1.StimA2Key(ncL2);
                
                    % % Make an index pointing to the correct index in FileKeys/TestKeys
                    % [~,indA1] = ismember(tab1.Folder1Key, FolderKeys);
                    % [~,indA2] = ismember(tab1.Folder2Key, FolderKeys);
                    % tab1.indA1 = indA1;
                    % tab1.indA2 = indA2;
                
                    % logical arrays for trials where stim1/Stim2 changes
                    L1 = tab1.StimTestType==1 & tab1.StimChangeTF;
                    L2 = tab1.StimTestType==2 & tab1.StimChangeTF;
                
                    % Make StimB keys
                    if any(L1)
                        %StimB1Key(L1) = imageset.make_keys(TestKeys(indA1(L1)), tab1.File1Key(L1));
                        StimB1Key(L1) = imageset.make_keys(TestKeys(sub2ind(size(FolderKeys), tab1.Folder1KeyRow(L1), tab1.Folder1KeyColumn(L1))), tab1.File1Key(L1));
                    end
                    if any(L2)
                        %StimB2Key(L2) = imageset.make_keys(TestKeys(indA2(L2)), tab1.File2Key(L2));
                        StimB2Key(L2) = imageset.make_keys(TestKeys(sub2ind(size(FolderKeys), tab1.Folder2KeyRow(L2), tab1.Folder2KeyColumn(L2))), tab1.File2Key(L2));
                    end
                    tab1.StimB1Key = StimB1Key;
                    tab1.StimB2Key = StimB2Key;
                
                    % Make life easier when analyzing data by assigning the "scientific"
                    % trial type HH,HL,LH,LL
                    %folderKeyIndices = horzcat(indA1, indA2);
                    %folderKeyIndices = horzcat(tab1.Folder1KeyRow, tab1.Folder2KeyRow);
                    hl={'H','L'};
                
                    % logical arrays for trials stim1/Stim2 is test type (regardless of 
                    % whether it changes)
                    L1 = tab1.StimTestType==1;
                    L2 = tab1.StimTestType==2;
                
                    sciTrialType = cell(height(tab1), 1);
                
                    sciTrialType(L1) = strcat(hl(tab1.Folder1KeyRow(L1)), hl(tab1.Folder2KeyRow(L1)));
                    sciTrialType(L2) = strcat(hl(tab1.Folder2KeyRow(L2)), hl(tab1.Folder1KeyRow(L2)));
                    tab1.sciTrialType = sciTrialType;
       
                    % Assign CueSide value
                    tab1.CueSide = cueSideThisTrialSet * ones(height(tab1), 1);

                    thisSetTable = [thisSetTable; tab1];
    
                    fprintf('i=%d: N=%d, %d trials generated\n', i, thisSetNums(i), height(tab1));
                end
            end

            % Now if there were multiple sets used - we will re-randomize the
            % order of trials.
            if length(thisSetNums) > 1
                thisSetTable = thisSetTable(randperm(height(thisSetTable)), :);
            end

            allTrialSets{itrialset} = thisSetTable;

        end
    else

        warning('Threshold trials expect single set (Num should have one row)');

        %% Threshold trials

        % The number of trials will be 8*nImages*nBase
        % where 8 = (folder key)*(StimTestType=1,2)*(StimChangeTF=0,1)
        % and nBase is the number of Base values tested.

        replacements = cell(5,1);
        columnNames=cell(5,1); 
    
        % Which image pair to use on a given trial?
        nImages = p.Results.Num;
        imageInd=randperm(nFileKeys, nImages);

        % Initial orientation direction for each image
        imageOri = (2*randi([0 1],nImages, 1))-1;


        % now randomize params
        %replacements{1} = reshape(randperm(nFileKeys, nImages), nImages, 1);
        replacements{1} = (1:nImages)';
        columnNames{1} = 'ImageIndex';
    
        % FolderKey
        replacements{2}=p.Results.FolderKeys;
        columnNames{2} = 'FolderKey';
    
        % TestType? L=1, R=2
        replacements{3}=[1;2];
        columnNames{3} = 'StimTestType';
    
        % change/nochange test
        replacements{4} = [0;1];
        columnNames{4} = 'StimChangeTF';
    
        % Base value (for rotations)
        replacements{5} = p.Results.Base;
        columnNames{5} = 'Base';
    
        % randomize across params
        tabTemp = randomizeParams('VariableNames', columnNames, 'Replacements', replacements);
        nTrials = height(tabTemp);

        % StimChangeType
        tabTemp.StimChangeType = tabTemp.StimChangeTF.*tabTemp.StimTestType;

        % Log array for stim on left(1) and right(2).
        L1=tabTemp.StimTestType==1;
        L2=tabTemp.StimTestType==2;

        Stim1Key=cell(nTrials, 1);
        Stim2Key=cell(nTrials, 1);
        Stim1Key(L1)=imageset.make_keys(tabTemp.FolderKey(L1), FileKeys(imageInd(tabTemp.ImageIndex(L1))));
        Stim1Key(~L1)={'BKGD'};
        Stim2Key(L2)=imageset.make_keys(tabTemp.FolderKey(L2), FileKeys(imageInd(tabTemp.ImageIndex(L2))));
        Stim2Key(~L2)={'BKGD'};

        tabTemp.StimA1Key = Stim1Key;
        tabTemp.StimB1Key = Stim1Key;
        tabTemp.StimA2Key = Stim2Key;
        tabTemp.StimB2Key = Stim2Key;


        Stim1Ori = zeros(nTrials, 1);
        Stim1Ori(L1) = imageOri(tabTemp.ImageIndex(L1));
        Stim2Ori = zeros(nTrials, 1);
        Stim2Ori(L2) = imageOri(tabTemp.ImageIndex(L2));
        tabTemp.Stim1Ori = Stim1Ori;
        tabTemp.Stim2Ori = Stim2Ori;

        allTrialSets{1} = tabTemp;

    end


    % Now finish off columns in all the generated trial sets. Break each
    % set into blocks if requested. 

    for itrialset = 1:size(allTrialSets, 1)

        tabTemp = allTrialSets{itrialset};
        nTrials = height(tabTemp);
        fprintf('trial set %d: %d trials\n', itrialset, nTrials);
    
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
            allTrialSets{itrialset} = blocks;
        else
            allTrialSets{itrialset} = tabTemp;
        end
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

