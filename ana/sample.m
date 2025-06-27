% load big file
Y=load('/home/dan/work/cclab/ethosal/ana/test.mat');
R = Y.output;

% logical indices for all completed trials and all correct trials
lCompleted = R.Started & R.tResp>0 & R.iResp>-1;
lCorrect  = lCompleted & R.StimChangeTF==R.iResp;

% logical indices for each block number
% lBlockNumberInd is the same HEIGHT as the table. Each column is a logical
% index for the block number: lBlockNumberInd(:,1) corresponds to all
% trials from block 1
blockNumbers=unique(R.BlockNum);
lBlockNumberInd = R.BlockNum==blockNumbers';

% left/right cue - need this to distinguish block 1 left from block 1
% right, e.g.
lCueLeft = R.CueSide==1;
lCueRight = R.CueSide==2;

% attention - attend-in and attend-out
lAttendIn = ismember(R.CueSide, [1,2]) & R.CueSide==R.StimTestType;
lAttendOut = ismember(R.CueSide, [1,2]) & R.CueSide~=R.StimTestType;

% loop over unique subject names.
subjects = unique(R.SubjID);
fprintf('There are %d subjects in the data set\n', length(subjects));
for i=1:length(subjects)

    % logindex for all this subject's trials
    % Each string in the SubjID column is stored as a cell (which contains
    % a string). That means this fails because you can't use "==" on cells.
    %lSubject = R.SubjID==subjects{i};
    % Instead, this works
    lSubject = strcmp(R.SubjID, subjects{i});

    % count complete trials
    nCompleted = sum(lSubject&lCompleted);

    % Count complete trials per block
    % blockNumbers should be 1:8 for this data set. It comes as a column
    % vector below. When its used for the log index, we turn it on its
    % side. The log index lBlockNumberInd has the same height as the table
    % 'R', and each column identifies the trials from that block for this
    % subject.
    nCompletedByBlock = sum(lSubject & lCompleted & lBlockNumberInd);
    nCompletedByBlockLeft = sum(lSubject & lCompleted & lCueLeft & lBlockNumberInd);
    nCompletedByBlockRight = sum(lSubject & lCompleted & lCueRight & lBlockNumberInd);

    nAttendIn = sum(lSubject & lCompleted & lAttendIn);
    nAttendOut = sum(lSubject & lCompleted & lAttendOut);
    %fprintf('in %d out %d\n', nAttendIn, nAttendOut);

    % Did subject complete all trials?
    % Expecting 1600 total, 100 per block. Attend-In=1280, attend-out=320
    if ~all(nCompletedByBlockLeft==100 & nCompletedByBlockRight==100) || nAttendIn~= 1280 || nAttendOut ~= 320
        fprintf('MISSING TRIALS: Subject %s # completed: %d by block: \n', subjects{i}, nCompleted);
        fprintf(['Left : ', repmat('%d ',1,length(nCompletedByBlockLeft)), '\n'], nCompletedByBlockLeft);
        fprintf(['Right: ', repmat('%d ',1,length(nCompletedByBlockRight)), '\n'], nCompletedByBlockRight);
        fprintf('Attend-in: %d Attend-out: %d\n', nAttendIn, nAttendOut);
    end    


end

