Z=load("C:/Users/cclab/Desktop/work/data/input/rimg_exp_ColorCue-30-10-ALL.mat");

for i=1:length(Z.blockset)
    ifkey = U(Z.blockset(i).trials.ImagePairIndex,2);
    ftmp=cellstr(num2str(ifkey));
    fkey = cellfun(@(x) strtrim(x), ftmp, 'UniformOutput', false);

    % assign to File1Key ad File2Key
    Z.blockset(i).trials.File1Key = fkey;
    Z.blockset(i).trials.File2Key = fkey;

    % now reassign StimA1Key, StimA2Key
    Z.blockset(i).trials.StimA1Key = imageset.make_keys(Z.blockset(i).trials.Folder1Key, Z.blockset(i).trials.File1Key);
    Z.blockset(i).trials.StimA2Key = imageset.make_keys(Z.blockset(i).trials.Folder2Key, Z.blockset(i).trials.File2Key);

    %% Now make B stim keys. 
    % First, initialize all of them to 'BKGD'. 
    StimB1Key=cell(size(Z.blockset(i).trials.StimA1Key));
    [StimB1Key{:}] = deal('BKGD');
    StimB2Key=cell(size(Z.blockset(i).trials.StimA1Key));
    [StimB2Key{:}] = deal('BKGD');

    % logical arrays for trials where stim1/Stim2 do not change
    ncL1 = Z.blockset(i).trials.StimTestType==1 & ~Z.blockset(i).trials.StimChangeTF;
    ncL2 = Z.blockset(i).trials.StimTestType==2 & ~Z.blockset(i).trials.StimChangeTF;

    % For no-change trials, the B key is same as A key.
    StimB1Key(ncL1) = Z.blockset(i).trials.StimA1Key(ncL1);
    StimB2Key(ncL2) = Z.blockset(i).trials.StimA2Key(ncL2);

    % logical arrays for trials where stim1/Stim2 changes
    L1 = Z.blockset(i).trials.StimTestType==1 & Z.blockset(i).trials.StimChangeTF;
    L2 = Z.blockset(i).trials.StimTestType==2 & Z.blockset(i).trials.StimChangeTF;

    % Make StimB keys
    FolderKeys = {'H'; 'L'};
    TestKeys = {'H'; 'L'};
    if any(L1)
        %StimB1Key(L1) = imageset.make_keys(TestKeys(indA1(L1)), Z.blockset(i).trials.File1Key(L1));
        StimB1Key(L1) = imageset.make_keys(TestKeys(sub2ind(size(FolderKeys), Z.blockset(i).trials.Folder1KeyRow(L1), Z.blockset(i).trials.Folder1KeyColumn(L1))), Z.blockset(i).trials.File1Key(L1));
    end
    if any(L2)
        %StimB2Key(L2) = imageset.make_keys(TestKeys(indA2(L2)), Z.blockset(i).trials.File2Key(L2));
        StimB2Key(L2) = imageset.make_keys(TestKeys(sub2ind(size(FolderKeys), Z.blockset(i).trials.Folder2KeyRow(L2), Z.blockset(i).trials.Folder2KeyColumn(L2))), Z.blockset(i).trials.File2Key(L2));
    end

    Z.blockset(i).trials.StimB1Key = StimB1Key;
    Z.blockset(i).trials.StimB2Key = StimB2Key;

end