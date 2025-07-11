function [results] = ethologV2(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    experimentStartTime = GetSecs;
    

%% Create a parser and parse input arguments
    p = inputParser;
    
    p.addRequired('Trials', @(x) isValidEthologTrialsInput(x));
    p.addRequired('Images', @(x) isa(x, 'imageset'));
    p.addRequired('ScreenWH', @(x) isempty(x) || (isnumeric(x) && isvector(x) && length(x)==2));
    p.addRequired('ScreenDistance', @(x) isempty(x) || (isnumeric(x) && isscalar(x)));


    % The output filename will be formed like this:
    %
    % OutputFolder/datetime_subjectID_OuptutBase.mat
    % 
    % The 'OutputFolder' and 'SubjectID' args are required. 
    %
    % If a single block of trials is used (i.e. a table is passed in as the
    % 'Trials' required arg), then 'OutputBase' must be supplied.
    %
    % If a blockset is used (the 'Trials' arg is a struct), then 'OutputBase' 
    % is ignored - it is taken from the field 'outputbase' in the blockset.
    % 
    % The subjectID and OutputFolder are passed as input arguments (must be
    % passed for all cases).
    % 

    goalDirectedTypes = {'none', 'existing', 'stim1', 'stim2'};
    p.addParameter('GoalDirected', 'none', @(x) ismember(x, goalDirectedTypes));
    p.addParameter('OutputBase', 'ZZZZ', @(x) ischar(x));
    p.addParameter('OutputFolder', '.', @(x) isfolder(x));
    p.addParameter('OutputFile', 'eth_output.mat', @(x) ischar(x));    
    p.addParameter('SubjectID', 'dan', @(x) ischar(x));
    p.addParameter('StartBlock', 1, @(x) isscalar(x) && isnumeric(x));  % for blocksets only, ignored otherwise.

    % These will be applied to all blocks
    p.addParameter('ITI', 0.5, @(x) isscalar(x));   % inter-trial interval.
    p.addParameter('Screen', 0, @(x) isscalar(x));
    p.addParameter('Rect', [], @(x) isempty(x) || (isvector(x) && length(x) == 4));
    p.addParameter('Bkgd', [.5 .5 .5], @(x) isrow(x) && length(x) == 3);

    defaultBreakParams = {
        .25, 'You''re done 1/4 of the trials in this block.';
        .5, 'You''re halfway through this block!';
        .75, 'That''s 3/4 of the trials in this block. Almost done!'
        };

    p.addParameter('Breaks', true, @(x) islogical(x));
    p.addParameter('BreakParams', defaultBreakParams, @(x) iscell(x) && size(x,2)==2);
    p.addParameter('BreakTime', 3, @(x) isscalar(x) && isnumeric(x));

    p.addParameter('StatusBreaks', 40, @(x) isnumeric(x) && isscalar(x));

    % djs by default no cues are used. 
    p.addParameter('CueColors', [1, 0, 0; 0, 0, 1]', @(x) size(x,1)==4);
    p.addParameter('CueWidth', 2, @(x) isscalar(x));
    p.addParameter('UseCues', false, @(x) islogical(x));


    % Overrides for trial parameters
    p.addParameter('FixptDiam', 1, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('FixptXY', [0,0], @(x) isvector(x) && length(x)==2);
    p.addParameter('FixptColor', [0,0,0], @(x) all(size(x) == [1 3]));  % color should be row vector on cmd line
    p.addParameter('FixptWindowDiam', 3, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('Stim1XY', [-7,0], @(x) isvector(x) && length(x)==2);
    p.addParameter('Stim2XY', [7,0], @(x) isvector(x) && length(x)==2);

    % for threshold tests - implies that "a" stim is a single stim, and "b"
    % stim will be in same position, depending on if GaborTest or
    % CImageTest is set. 
    p.addParameter('Threshold', false, @(x) islogical(x));

    % Specify the test type as 'Gabor', or 'Image'. Type 'Contrast' removed
    % in this version. djs 8/28/2024

    testTypes = {'Gabor', 'Image', 'RotatedImage', 'Flip'};
    p.addParameter('ExperimentTestType', 'Flip', @(x) any(validatestring(x, testTypes)));

    % These are for gabors. The Gabors are only used if GaborTest or 
    % GaborThresh is true,otherwise the parameters here are ignored.
    p.addParameter('GaborSF', 0.05, @(x) x>0);
    p.addParameter('GaborSC', 100, @(x) x>0);

    p.addParameter('SkipSyncTests', 0, @(x) isscalar(x) && (x==0 || x==1));
    p.addParameter('EyelinkDummyMode', 1,  @(x) isscalar(x) && (x == 0 || x == 1));
    p.addParameter('Verbose', 0, @(x) isscalar(x) && isnumeric(x) && x>=0);
    p.addParameter('Fovx', 30, @(x) isscalar(x));

    % Where to look for responses. The 'Saccade' is intended for usage with
    % eyelink dummy mode ('EyelinkDummyMode', 1) - which is the default.
    responseTypes = {'Saccade', 'MilliKey'};
    p.addParameter('Response', 'Saccade', @(x) any(validatestring(x, responseTypes)));
    p.addParameter('MilliKeyIndex', 0, @(x) isscalar(x));
    
    % make an annoying beep telling subject right/wrong response
    p.addParameter('Beep', false, @(x) islogical(x));

    % visual feedback
    p.addParameter('Feedback', false, @(x) islogical(x));
    
    % keyboard index is needed for experimenter controls during the expt.
    % See docs for details.
    p.addParameter('KeyboardIndex', 0, @(x) isscalar(x));

    % Now parse the input arguments
    p.parse(varargin{:});

    % Initializations based on results of parse.
    ourVerbosity = p.Results.Verbose;
    images = p.Results.Images;

    % This will determine the "test" type - what is shown as the "B" phase.
    % Contrast is the original usage: trials must have a 'Delta'
    bStimType = validatestring(p.Results.ExperimentTestType, testTypes);

    subjectResponseType = validatestring(p.Results.Response, responseTypes);

    %% Initialize blockStruct
    %
    % Warning: After this point in the code DO NOT USE OR REFER TO these
    % values: p.Results.Trials, p.Results.OutputFile,
    % p.Results.GoalDirected, and use the values in blockStruct(iblock)

    if istable(p.Results.Trials)
        blockStruct.trials = p.Results.Trials;
        blockStruct.outputfile = p.Results.OutputFile;
        blockStruct.goaldirected = p.Results.GoalDirected;
        blockStruct.text = 'Please hit any button on the millikey to continue.';
    else
        blockStruct = p.Results.Trials;
    end

    % issue WARNING and EXIT if test type is anything other than 'Image'
    if ~any(strcmp(bStimType, {'Image','RotatedImage','Flip'}))
        error('Responses are not configured correctly for anything other than Image/RotatedImage/Flip type');
    end

    % useful functions for getting progress - pass 'results' as arg
    fnCompleteTrials=@(x) sum(x.Started & x.tResp>0 & x.iResp>-1);
    fnCorrectTrials=@(x) sum(x.Started & x.tResp>0 & x.iResp==x.StimChangeTF);
    fnNoRespTrials=@(x) sum(x.Started & x.iResp<0);
    fnRemainingTrials=@(x) sum(~x.Started);

    % Create a cleanup object, that will execute whenever this script ends
    % (even if it crashes). Use it to restore matlab to a usable state -
    % see cleanup() below.
    myCleanupObj = onCleanup(@cleanup);


    %% Initialize PTB and hardware. 

    % PTB defaults
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', p.Results.SkipSyncTests);
    
    % Open window for visual stim
    [windowIndex, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
    
    % pixel-degree converter
    if ~isempty(p.Results.ScreenWH)
        converter = pixdegconverter(windowRect, p.Results.ScreenWH, p.Results.ScreenDistance);
    else
        converter = pixdegconverter(windowRect, p.Results.Fovx);
    end

    % Keyboard used for input from operator
    if ~p.Results.KeyboardIndex
        error('Need to specify keyboard index');
    end
    KbQueueCreate(p.Results.KeyboardIndex);
    KbQueueStart(p.Results.KeyboardIndex);
    ListenChar(-1);

    % input response device if needed
    if strcmp(subjectResponseType, 'MilliKey')
        if ~p.Results.MilliKeyIndex
            error('If MilliKey used as response device, you must supply the keyboard index with MilliKeyIndex');
        end
        millikey = responder(p.Results.MilliKeyIndex);
    end

    % Init audio - BEFORE the tracker is initialized ()
    beeper = twotonebeeper(true);

    % init eye tracker.     
    if ~p.Results.EyelinkDummyMode
        warning('Initializing tracker. Will switch tracker to CameraSetup SCREEN - calibrate and hit ExitSetup');
    end
    trackerFilename = 'etholog';
    tracker = eyetracker(p.Results.EyelinkDummyMode, p.Results.ScreenWH, p.Results.ScreenDistance, trackerFilename, windowIndex, 'Verbose', ourVerbosity);

    % For gabor tests, must generate a texture here, after the window is
    % opened.
    if strcmp(bStimType, 'Gabor')
        % This struct gets passed (as an array from struct2array) to
        % DrawTextures.
        GaborParams.phase = 0;
        GaborParams.sf = p.Results.GaborSF;
        GaborParams.sc = p.Results.GaborSC;
        GaborParams.contrast = 100;
        GaborParams.aspect = 1.0;
        GaborParams.z1 = 0;
        GaborParams.z2 = 0;
        GaborParams.z3 = 0;
        % need height and width of images in imageset
        rectTemp = images.UniformOrFirstRect;
        GaborTex = CreateProceduralGabor(windowIndex, RectWidth(rectTemp), RectHeight(rectTemp), 0, [0.5 0.5 0.5 0.0]);
    else 
        GaborTex = -1;
    end


    % In general, nice to have a background texture laying around
    BkgdTex = images.texture(windowIndex, 'BKGD');

    %% Initialize experimental parameters that apply to all blocks

    % background color
    bkgdColor = [.5 .5 .5];

    % fixation point color
    fixColor = p.Results.FixptColor;

    % Diameter of fixation point/cross in pixels
    fixDiamPix = converter.deg2pix(p.Results.FixptDiam);

    % on-screen position of fixation (center) point. deg2scr converts to
    % screen-pixel values (where 0,0 is upper left corner, y positive down.
    fixXYScr = converter.deg2scr(p.Results.FixptXY);

    % % Lines for the fixation "+" sign. The array fixLines has x,y values in
    % % rows, one column for each line segment.
    % fixLines = [ ...
    %     fixXYScr(1) + fixDiamPix/2, fixXYScr(2); ...
    %     fixXYScr(1) - fixDiamPix/2, fixXYScr(2); ...
    %     fixXYScr(1), fixXYScr(2) + fixDiamPix/2; ...
    %     fixXYScr(1), fixXYScr(2) - fixDiamPix/2
    %     ]';
    stim1XYScr = converter.deg2scr(p.Results.Stim1XY);
    stim2XYScr = converter.deg2scr(p.Results.Stim2XY);


    % Create Fixation point object
    fixpt = FixationPoint(fixXYScr,fixDiamPix,fixColor,'+',...
            dirvecs=[stim1XYScr - fixXYScr; stim2XYScr - fixXYScr ]);

    % feedback colors, and feedback animator
    feedbackColorCorrect = [.5,.55,.5];
    feedbackColorIncorrect = [.55,.5,.5];
    feedbackStruct = struct('rect', [], 'color', [1,1,1], 'on', 0, 'ramp', p.Results.ITI/2, 'off', 0.9*p.Results.ITI, 'thick', 8);
    feedbackAnimator = AnimMgr(@visualFeedbackRectAnimator, [0,p.Results.ITI], feedbackStruct);

    % Fixation window. The rect will be used with the eyetracker to test
    % for looking/not-looking
    fixWindowDiamPix = converter.deg2pix(p.Results.FixptWindowDiam);
    fixWindowRect = CenterRectOnPoint([0 0 fixWindowDiamPix fixWindowDiamPix], fixXYScr(1), fixXYScr(2));
    fixFeedbackRect = CenterRectOnPoint(images.UniformOrFirstRect, fixXYScr(1), fixXYScr(2));



    %% per-block initializations
    bAbortBlockset = false;
    iblockInitial = 1;
    if length(blockStruct) > 1
        iblockInitial = p.Results.StartBlock;
    end
    for iblock = iblockInitial:length(blockStruct)

        fprintf('Starting block %d/%d: %d trials.\n', iblock, length(blockStruct), height(blockStruct(iblock).trials));
        
        % Prepare output file name. Make sure an existing file does not get
        % clobbered.

        % blockStruct might have a field named 'outputfile' - when the
        % input is a single block, and a full output filename is provided.
        % when the input was a blockset, then each block has a
        % corresponding 'tag', which is used to construct the filename.

        if ismember('outputfile', fieldnames(blockStruct(iblock)))
            if isfile(blockStruct(iblock).outputfile)
                warning('OutputFile %s already exists. Finding a suitable name...', blockStruct(iblock).outputfile);
                [path, base, ext] = fileparts(blockStruct(iblock).outputfile);
                [ok, outputFilename] = makeNNNFilename(fullfile(path, [base, '_NNN', ext]));
                if ~ok
                    error('Cannot form usable filename using folder %s and basename %s', path, base);
                end
            else
                outputFilename = blockStruct(iblock).outputfile;
            end
        else
            datestr = char(datetime('now','Format','yyyy-MM-dd-HHmm'));
            base = sprintf('%s_%s_%s.mat', datestr, p.Results.SubjectID, blockStruct(iblock).outputbase);
            outputFilename = fullfile(p.Results.OutputFolder, [base, '.mat']);
            if isfile(outputFilename)
                [ok, outputFilename] = makeNNNFilename(fullfile(p.Results.OutputFolder, [base, '_NNN.mat']));
                if ~ok
                    error('Cannot form usable filename using folder %s and basename %s', path, base);
                end
            end
        end
        fprintf('\n*** Using output filename %s\n', outputFilename);    
    
        % The table 'results' will be used to hold all parameters and results
        % for this block. 
        % 'itrial' is the row of the current trial
        % 'NumTrials' is the height of the original results table. This number 
        % WILL NOT CHANGE, though more trials may be appended to the array 
        % (when a trial is incomplete, e.g.)
        results = blockStruct(iblock).trials;
        NumTrials = height(results);
        itrial = 1;
    
    
        % For taking breaks. We check regardless of whether its been requested.
        % Use a text size that makes characters be about 1 degree on screen for
        % short messages.
        breakTimeMilestones = OneShotMilestone([p.Results.BreakParams{:,1}]);
        statusMilestones = [];
        if p.Results.StatusBreaks > 0
            statusMilestones = OneShotMilestone(p.Results.StatusBreaks:p.Results.StatusBreaks:NumTrials);
        end
        textSizeForMilestones = getTextSizePix(converter.deg2pix(1), windowIndex);
        fprintf('Using text size %d for %f pixels\n', textSizeForMilestones, converter.deg2pix(1));
    
    
        % If using goal-directed cues, then we MUST have a column named
        % GoalCues, or else the parameter CueSide must be set, and the column
        % will be created and assigned that value. 
        usingGoalDirectedCues = false;
        switch blockStruct(iblock).goaldirected
            case 'none'
                results.CueSide = zeros(height(results), 1);
                usingGoalDirectedCues = false;
                % nothing to do
            case 'existing'
                % trials must have 'CueSide' column
                assert(ismember('CueSide', fieldnames(results)) && all(ismember(results.CueSide,[1,2])),...
                    'Input trial table must have column CueSide populated with 1s and 2s');
                usingGoalDirectedCues = true;
            case 'stim1'
                usingGoalDirectedCues = true;
                results.CueSide = ones(height(results), 1);
            case 'stim2'
                usingGoalDirectedCues = true;
                results.CueSide = 2*ones(height(results), 1);
            otherwise
                error('Unknown value for GoalDirected parameter');
        end
    
        % AnimMgr for putting goal-directed cues on screen during fixation
        % period.
        if usingGoalDirectedCues
            goalCueStruct.fixpt = fixpt;
            goalCueStruct.cueDirIndex = 0;   % This is set to 1 or 2 per trial
            goalCueAnim = AnimMgr(@ethologFixationCueCallback);
        end
    
    
        % Use this for managing pauses. When a <space> key is hit, this is
        % set to indicate we should pause ASAP. Not all states allow
        % pausing, so this is a buffer allowing us to wait until it is OK
        % to pause. 
        bPausePending = false;
    
        % state manager and flag for quitting
        stateMgr = statemgr('START', ourVerbosity>0);
        bQuit = false;

        %% Intermission
        [ok, ~] = intermission(windowIndex, millikey, blockStruct(iblock).text, 18);
        if ~ok
            fprintf('Intermission timed out. This could mean the millikey responder is not working! Pausing....');
            stateMgr.transitionTo('WAIT_PAUSE');
        end

        %% Start trial loop
        % while ~bQuit && ~strcmp(stateMgr.Current, 'DONE')
        while ~bQuit
            
            % any keys pressed? 
            [keyPressed, keyCode,  ~, ~] = checkKbdQueue(p.Results.KeyboardIndex);
            if keyPressed
                switch keyCode
                    case KbName('space')
    
                        % un-do a pending pause?
                        if bPausePending
                            bPausePending = false;
                            fprintf(1, 'Pending pause cancelled.\n');
                        elseif strcmp(stateMgr.Current, 'WAIT_PAUSE')
                            % Resume from pause by transitioning
                            % to the START state. The current trial, with index
                            % 'itrial', is started.
                            stateMgr.transitionTo('START');
                            if (ourVerbosity > -1); fprintf('Resume after pause.\n'); end
                        else
                            bPausePending = true;
                            fprintf('Pause pending...\n');
                        end
                    case KbName('q')
                            % trial will have to be flushed. TODO. 
                            Screen('FillRect', windowIndex, bkgdColor);
                            Screen('Flip', windowIndex);
                            stateMgr.transitionTo('DONE');
                            if (ourVerbosity > -1); fprintf('Quit from kbd.\n'); end
                    case KbName('k')
                            % Quit this block and all others
                            Screen('FillRect', windowIndex, bkgdColor);
                            Screen('Flip', windowIndex);
                            bAbortBlockset = true;
                            stateMgr.transitionTo('DONE');
                            if (ourVerbosity > -1); fprintf('Quit/abort from kbd.\n'); end                            
                    case KbName('d')
                        % this is for doing drift correct, but only if we are
                        % paused.
                        if strcmp(stateMgr.Current, 'WAIT_PAUSE')
                            % draw fixpt, kick off drift correction
                            Screen('FillRect', windowIndex, bkgdColor);
                            %Screen('DrawLines', windowIndex, fixLines, 4, fixColor');
                            fixpt.draw(windowIndex);
                            Screen('Flip', windowIndex);
                            tracker.drift_correct(fixXYScr(1), fixXYScr(2));
                            
                            % Re-generate textures that might have been cleared
                            % by the tracker. It seems that the tracker might
                            % clear textures during the drift correction (maybe
                            % because they use textures for the calibration
                            % dots?)
                            if GaborTex > 0
                                GaborTex = CreateProceduralGabor(windowIndex, RectWidth(rectTemp), RectHeight(rectTemp), 0, [0.5 0.5 0.5 0.0]);
                                fprintf('Regenerated gabor texture id %d\n', GaborTex);
                            end
                            BkgdTex = images.texture(windowIndex, 'BKGD');
                            fprintf('Regenerated background texture id %d\n', BkgdTex);
    
                            % djs 2024-09-04. 
                            % This used to transition to TRIAL_COMPLETE. 
                            stateMgr.transitionTo('START');
                        end
                    case KbName('s')
                        % this is for getting into camera setup. Should be able
                        % to re-calibrate from here. Not sure about drift
                        % correction.
                        if strcmp(stateMgr.Current, 'WAIT_PAUSE')
                            fprintf('Entering camera setup. Hit ExitSetup to return to trials.\n');
                            tracker.do_tracker_setup();
    
                            % Re-generate textures that might have been cleared
                            % by the tracker. It seems that the tracker might
                            % clear textures during the drift correction (maybe
                            % because they use textures for the calibration
                            % dots?)
                            if GaborTex > 0
                                GaborTex = CreateProceduralGabor(windowIndex, RectWidth(rectTemp), RectHeight(rectTemp), 0, [0.5 0.5 0.5 0.0]);
                                fprintf('Regenerated gabor texture id %d\n', GaborTex);
                            end
                            BkgdTex = images.texture(windowIndex, 'BKGD');
                            fprintf('Regenerated background texture id %d\n', BkgdTex);
    
                            % djs 2024-09-04. 
                            % This used to transition to TRIAL_COMPLETE. 
                            stateMgr.transitionTo('START');
                        end
                    otherwise
                        if (ourVerbosity > -1); fprintf('Keys:\n<space> - toggle pause\n\n');end
                end
            end
    
                        
            switch stateMgr.Current
                case 'START'
    
                    % In this state, initialize parameters, textures, etc that
                    % are unique to this trial. 
    
                    % get a struct with just trial params.  
                    trial = table2struct(results(itrial, :));
    
                    % rects for the textures in trial
                    stim1Rect = CenterRectOnPoint(images.rect(trial.StimA1Key), stim1XYScr(1), stim1XYScr(2));
                    stim2Rect = CenterRectOnPoint(images.rect(trial.StimA2Key), stim2XYScr(1), stim2XYScr(2));    
    
                    % Somehow, get the textures themselves.
                    % texturesA/texturesB are 2-element arrays, the
                    % positions correspond to the stim1 and stim2.
                    texturesA = [0,0];
                    texturesB = [0,0];                    
                    switch bStimType
                        case 'Gabor'
                            texturesA = [ ...
                                images.texture(windowIndex, trial.StimA1Key), ...
                                images.texture(windowIndex, trial.StimA2Key)
                                ];
                            % For threshold gabor, place gabor at test site,
                            % bkgd on other side.
                            if p.Results.Threshold
                                texturesB = [BkgdTex, BkgdTex];
                                texturesB(trial.StimTestType) = GaborTex;
                            else
                                texturesB = [GaborTex, GaborTex];
                            end
    
                            switch trial.StimChangeType
                                case 0
                                    GaborOri = [90, 90];
                                case 1
                                    GaborOri = [0, 90];
                                case 2
                                    GaborOri = [90, 0];
                                otherwise
                                    error('StimTestType can only be 0, 1, or 2');
                            end
    
                            
                            GaborParams.contrast = trial.Delta;
    
                        case 'Flip'
    
                            % A presentation will have images flipped if their
                            % Ori (Stim1Ori, Stim2Ori) is negative. 
                            funcPtr = @(x) flip(x,2);
                            if trial.Stim1Ori < 0
                                texturesA(1) = images.texture(windowIndex, trial.StimA1Key, funcPtr);
                            else
                                texturesA(1) = images.texture(windowIndex, trial.StimA1Key);
                            end
                            if trial.Stim2Ori < 0
                                texturesA(2) = images.texture(windowIndex, trial.StimA2Key, funcPtr);
                            else
                                texturesA(2) = images.texture(windowIndex, trial.StimA2Key);
                            end
    
                            if trial.StimTestType==1
                                texturesB(2) = images.texture(windowIndex, trial.StimB2Key);
                                if trial.StimChangeTF
                                    itmp = -trial.Stim1Ori;
                                else
                                    itmp = trial.Stim1Ori;
                                end
                                if itmp < 0
                                    texturesB(1) = images.texture(windowIndex, trial.StimB1Key, funcPtr);
                                else
                                    texturesB(1) = images.texture(windowIndex, trial.StimB1Key);
                                end
                            elseif trial.StimTestType==2
                                texturesB(1) = images.texture(windowIndex, trial.StimB1Key);
                                if trial.StimChangeTF
                                    itmp = -trial.Stim2Ori;
                                else
                                    itmp = trial.Stim2Ori;
                                end
                                if itmp < 0
                                    texturesB(2) = images.texture(windowIndex, trial.StimB2Key, funcPtr);
                                else
                                    texturesB(2) = images.texture(windowIndex, trial.StimB2Key);
                                end
                            end
                        case {'Image','RotatedImage'}
    
                            texturesA = [images.texture(windowIndex, trial.StimA1Key), images.texture(windowIndex, trial.StimA2Key)];
                            texturesB = [images.texture(windowIndex, trial.StimB1Key), images.texture(windowIndex, trial.StimB2Key)];
    
                            % Rotated images must have fields 'Stim1Ori' and
                            % 'Stim2Ori', which should be +-1. 
                            % For either 1 or 2 stim, the initial rotation is 
                            % Stim1Ori * Base
                            % or 
                            % Stim2Ori * Base
                            % The changed stim will have its final rotation
                            % (initial rotation) * -1
    
                            rotationAnglesA = [trial.Stim1Ori * trial.Base, trial.Stim2Ori * trial.Base];
                            rotationAnglesB = rotationAnglesA;
                            switch trial.StimChangeType
                                case 1
                                    rotationAnglesB(1)=rotationAnglesA(1) * -1;
                                case 2
                                    rotationAnglesB(2)=rotationAnglesA(2) * -1;
                            end
    
                    end
                    stateMgr.transitionTo('DRAW_FIXPT');
                    
                    % results
                    results.Started(itrial) = true;
    
                    % start tracker recording
                    tracker.start_recording();
    
                case 'DRAW_FIXPT'
                    % Draw fixation cross on screen
                    Screen('FillRect', windowIndex, bkgdColor);
                    fixpt.draw(windowIndex);
                    %Screen('DrawLines', windowIndex, fixLines, 4, fixColor');
                    Screen('Flip', windowIndex);
    
                    % Draw cross and box on tracker screen
                    tracker.draw_cross(fixXYScr(1), fixXYScr(2), 15);
                    tracker.draw_box(fixWindowRect(1), fixWindowRect(2), fixWindowRect(3), fixWindowRect(4), 15);
    
                    stateMgr.transitionTo('WAIT_ACQ');
                case 'WAIT_ACQ'
                    % no maximum here, could go forever
                    % djs - a pending pause is honored here. 
                    if bPausePending
                        % reset trial to not-Started
                        results.Started(itrial) = false;
                        stateMgr.transitionTo('CLEAR_THEN_PAUSE');
                    elseif tracker.is_in_rect(fixWindowRect)
                        stateMgr.transitionTo('WAIT_FIX');
                        if usingGoalDirectedCues
                            goalCueStruct.cueDirIndex = trial.CueSide;
                            goalCueAnim.start(@ethologFixationCueCallback, [0, trial.FixationTime], goalCueStruct);
                        end
                    end
                case 'WAIT_FIX'
                    if bPausePending
                        % reset trial to not-Started
                        results.Started(itrial) = false;
                        stateMgr.transitionTo('CLEAR_THEN_PAUSE');
                    elseif stateMgr.timeInState() > trial.FixationTime
                        stateMgr.transitionTo('DRAW_A');
                    elseif ~tracker.is_in_rect(fixWindowRect)
                        stateMgr.transitionTo('FIXATION_BREAK_EARLY');
                    else
                        if usingGoalDirectedCues
                            goalCueAnim.animate(windowIndex) && Screen('Flip', windowIndex);
                        end
                    end
                case 'FIXATION_BREAK_EARLY'
                    % clear screen, then wait for a little bit
                    Screen('FillRect', windowIndex, bkgdColor);
                    Screen('Flip', windowIndex);
                    stateMgr.transitionTo('FIXATION_BREAK_EARLY_WAIT');
                case 'FIXATION_BREAK_EARLY_WAIT'
                    if stateMgr.timeInState() > trial.FixationBreakEarlyTime
                        stateMgr.transitionTo('DRAW_FIXPT');
                    end
                case 'DRAW_A'
                    % draw textures, cues if used, and fixation cross on
                    % screen.
                    Screen('FillRect', windowIndex, bkgdColor);
                    switch bStimType
                        case {'Gabor','Images','Flip'}
                            Screen('DrawTextures', windowIndex, texturesA, [], [stim1Rect;stim2Rect]');
                        case 'RotatedImage'
                            Screen('DrawTextures', windowIndex, texturesA, [], [stim1Rect;stim2Rect]', rotationAnglesA);
                    end             
                    if p.Results.UseCues
                        Screen('FrameRect', windowIndex, p.Results.CueColors, [stim1Rect;stim2Rect]', p.Results.CueWidth);
                    end
                    fixpt.draw(windowIndex);
                    %Screen('DrawLines', windowIndex, fixLines, 4, fixColor');
    
                    % draw boxes for images on tracker
                    tracker.draw_box(stim1Rect(1), stim1Rect(2), stim1Rect(3), stim1Rect(4), 15);
                    tracker.draw_box(stim2Rect(1), stim2Rect(2), stim2Rect(3), stim2Rect(4), 15);
    
                    % flip and save the flip time
                    [ results.tAon(itrial) ] = Screen('Flip', windowIndex);
                    stateMgr.transitionTo('WAIT_A');
                case 'WAIT_A'
                    if stateMgr.timeInState() >= trial.SampTime
                        % if GapTime is zero, transition directly to DRAW_B
                        if trial.GapTime > 0
                            stateMgr.transitionTo('DRAW_AB');
                        else
                            stateMgr.transitionTo('DRAW_B');
                        end
                    elseif ~tracker.is_in_rect(fixWindowRect)
                        stateMgr.transitionTo('FIXATION_BREAK_LATE');
                    end
                case 'FIXATION_BREAK_LATE'
                    Screen('FillRect', windowIndex, bkgdColor);
                    Screen('Flip', windowIndex);
                    stateMgr.transitionTo('FIXATION_BREAK_LATE_WAIT');
                case 'FIXATION_BREAK_LATE_WAIT'
                    if stateMgr.timeInState() > trial.FixationBreakLateTime
                        stateMgr.transitionTo('TRIAL_COMPLETE');
                        results.iResp(itrial) = -4;
                    end                
                case 'DRAW_AB'
                    Screen('FillRect', windowIndex, bkgdColor);
                    fixpt.draw(windowIndex);
                    %Screen('DrawLines', windowIndex, fixLines, 4,fixColor');
                    [ results.tAoff(itrial) ] = Screen('Flip', windowIndex);
                    stateMgr.transitionTo('WAIT_AB');
                case 'WAIT_AB'
                    if stateMgr.timeInState() >= trial.GapTime
                        stateMgr.transitionTo('DRAW_B');
                    end
                case 'DRAW_B'
                    Screen('FillRect', windowIndex, bkgdColor);
                    if strcmp(bStimType, 'Gabor')
                        % struct2array removed R2024a? 
                        %paramsTemp = struct2array(GaborParams);
                        paramsTemp1 = struct2cell(GaborParams);
                        paramsTemp = [paramsTemp1{:}];
                        Screen('DrawTextures', windowIndex, texturesB, [], [stim1Rect;stim2Rect]', GaborOri, [], [], [], [], kPsychDontDoRotation, [paramsTemp;paramsTemp]');
                    elseif strcmp(bStimType, 'RotatedImage')
                        Screen('DrawTextures', windowIndex, texturesB, [], [stim1Rect;stim2Rect]', rotationAnglesB);
                    else
                        Screen('DrawTextures', windowIndex, texturesB, [], [stim1Rect;stim2Rect]');
                    end                    
                    if p.Results.UseCues
                        Screen('FrameRect', windowIndex, p.Results.CueColors, [stim1Rect;stim2Rect]', p.Results.CueWidth);
                    end
                    fixpt.draw(windowIndex);
                    %Screen('DrawLines', windowIndex, fixLines, 4, fixColor');
                    [ results.tBon(itrial) ] = Screen('Flip', windowIndex);
    
                    % Moved this from START_RESPONSE, so subject may respond as
                    % soon as B image is shown. The WAIT_B period will still
                    % run to completion, as responses are not checked there. 
                    % Can do that, but that's a little tricky. Since the test
                    % period is short, this seems OK to me. 
    
                    if strcmp(subjectResponseType, 'MilliKey')
                        millikey.start();
                    end
                    stateMgr.transitionTo('WAIT_RESPONSE_WITH_B');
                case {'WAIT_RESPONSE_WITH_B', 'WAIT_RESPONSE'}
                    response = 0;
                    tResp = 0;
    
                    isResponse = false;
                    switch subjectResponseType
                        case 'Saccade'
                            sac = tracker.saccade([stim1Rect;stim2Rect]');
                            % We should ensure that the rectangles cannot
                            % overlap!
                            if any(sac)
                                response = find(sac);
                                isResponse = true;
                                tResp = GetSecs;    % not an accurate measurement at all! 
                            end
                        case 'MilliKey'
                            [isResponse, response, tResp] = millikey.response();
                    end
                    if isResponse
                        stateMgr.transitionTo('TRIAL_COMPLETE');
                        if strcmp(subjectResponseType, 'MilliKey')
                            millikey.stop(true);
                        end
    
                        % record response
                        results.iResp(itrial) = response;
                        results.tResp(itrial) = tResp;
                        
                        % beep maybe
                        if p.Results.Beep
                            if results.iResp(itrial) == trial.StimChangeTF
                                beeper.correct();
                            elseif results.iResp(itrial) < 0
                                beeper.incorrect();
                            else
                                beeper.incorrect();
                            end
                        end
                    else
                        switch stateMgr.Current
                            case 'WAIT_RESPONSE_WITH_B'
                                if ~tracker.is_in_rect(fixWindowRect)
                                    stateMgr.transitionTo('FIXATION_BREAK_LATE');
                                elseif stateMgr.timeInState() >= trial.TestTime
                                    % still waiting for response, but clear
                                    % screen. Do a state change that doesn't
                                    % change the start time of the state - then
                                    % we can use the timeInState to test for
                                    % timeout on response.
                                    Screen('FillRect', windowIndex, bkgdColor);
                                    Screen('Flip', windowIndex);
                                    stateMgr.setCurrent('WAIT_RESPONSE');
                                end
                            case 'WAIT_RESPONSE'
                                if stateMgr.timeInState() >= trial.RespTime
                                    stateMgr.transitionTo('TRIAL_COMPLETE');
                                    results.iResp(itrial) = -3;
                                    results.tResp(itrial) = -1;
                                end
                            otherwise
                                error('unhandled state while waiting for response');
                        end
                    end
                case 'TRIAL_COMPLETE'
    
                    % clear stimulus screen
                    Screen('Flip', windowIndex);
    
                    % stop tracker recording
                    tracker.offline();
    
                    % clear tracker screen
                    tracker.command('clear_screen 0');
    
    
                    % stop millikey queue
                    if strcmp(subjectResponseType, 'MilliKey')
                        millikey.stop(true);
                    end
    
                    % save data
                    save(outputFilename, 'results');
    
                    % screen output update, AND update struct for feedback
                    if results.iResp(itrial) < 0
                        scc = 'o';
                        feedbackStruct.color = feedbackColorIncorrect;
                    elseif results.iResp(itrial) == results.StimChangeTF(itrial)
                        scc = '+';
                        feedbackStruct.color = feedbackColorCorrect;
                    else
                        scc = '-';
                        feedbackStruct.color = feedbackColorIncorrect;
                    end
                    switch results.StimChangeType(itrial)
                        case 0
                            feedbackStruct.rect = fixFeedbackRect;
                        case 1
                            feedbackStruct.rect = stim1Rect;
                        case 2
                            feedbackStruct.rect = stim2Rect;
                    end
    
                    % Screen output for experimenter. 
                    % nnnn TT CH RR CC AA II OO TA.00 TI.00 TO.00
                    % nnnn = trial number 
                    % TT = StimTestType [1,2]
                    % CH = StimChangeTF [0,1]
                    % RR = Response [0,1,-1]
                    % CC = correct/incorrect/incomplete [+,-,0)
                    % AA = % correct, all types
                    % II = % correct, attend-in
                    % OO = % correct, attend-out
                    % TA = treact, correct trials, all types
                    % TI = treact, correct trials, attend-in
                    % TO = treact, correct trials, attend-out
                    rates = ethRates(results);
                    % pctAll(itrial) = rates.correctPct;
                    % pctIn(itrial)  = rates.correctInPct;
                    % pctOut(itrial)  = rates.correctOutPct;
                    % treactAll(itrial) = rates.treact;
                    % treactIn(itrial) = rates.treactIn;
                    % treactOut(itrial) = rates.treactOut;
                    if itrial==1 || rem(itrial, 10)==0
                        fprintf('\n');
                        fprintf('Key: TT:TestType 1=L/2=R  CH:Change? 0/1  RR: Response 0/1  C: Correct +/-\n\n')
                        fprintf('---Trial Info--|---Accuracy----|---Reaction---\n');
                        fprintf('Trl# TT CH RR C All%%  In%%  Ou%%  tRAl tRIn tROu\n');
                    end
                    fprintf('%4d %2d %2d %2d %c %4.1f %4.1f %4.1f %4.2f %4.2f %4.2f\n', itrial, results.StimTestType(itrial), results.StimChangeTF(itrial), results.iResp(itrial), scc, 100*rates.correctPct, 100*rates.correctInPct, 100*rates.correctOutPct, rates.treact, rates.treactIn, rates.treactOut);
    
                    % nCompleted = fnCompleteTrials(results);
                    % nCorrect = fnCorrectTrials(results);
                    % nNoResp = fnNoRespTrials(results);
                    % nRemain = fnRemainingTrials(results);
    
    
                    % If the trial was NOT completed, append it to the end of
                    % the trial list for re-trying later.
                    if ~results.Started(itrial) || results.tResp(itrial) < 0 || results.iResp(itrial) < 0
                        results = [results;struct2table(trial)];
                    end
    
                    % increment trial
                    itrial = itrial + 1;
                    if itrial > height(results)
                        stateMgr.transitionTo('DONE');
                    else
                        % check if a pause is pending
                        if bPausePending
                            stateMgr.transitionTo('WAIT_PAUSE');
                        else
                            stateMgr.transitionTo('WAIT_ITI');
                            if p.Results.Feedback
                                feedbackAnimator.start(feedbackStruct);
                            end
                        end
                    end
    
                    % free textures, but not gabor textures.
                    Screen('Close', unique(setdiff([texturesA, texturesB], [GaborTex, BkgdTex])));
                    
                case 'WAIT_ITI'
                    if stateMgr.timeInState() >= p.Results.ITI
                        if p.Results.Breaks && breakTimeMilestones.check(itrial/height(results))
                            stateMgr.transitionTo('BREAK_TIME');
                        elseif p.Results.StatusBreaks > 0 && statusMilestones.check(fnCompleteTrials(results))
                            stateMgr.transitionTo('STATUS_BREAK_TIME');
                        else
                            stateMgr.transitionTo('START');
                        end
                    else
                        if p.Results.Feedback && feedbackAnimator.animate(windowIndex)
                            Screen('Flip', windowIndex);
                        end
                    end
                case 'BREAK_TIME'
                    % figure out which break we're on
                    ind = breakTimeMilestones.pass(itrial/height(results));
                    if isempty(ind)
                        % This shouldn't happen! The transition to this state
                        % should have been preceded by milestones.check==true
                        stateMgr.transitionTo('WAIT_ITI');
                    else
                        stateMgr.transitionTo('BREAK_TIME_WAIT');
    
                        % draw text on screen
                        oldTextSize = Screen('TextSize', windowIndex, textSizeForMilestones);
                        DrawFormattedText(windowIndex, p.Results.BreakParams{ind(1),2}, 'center','center',[1 1 1]);
                        Screen('Flip', windowIndex);
                        Screen('TextSize', windowIndex, oldTextSize);
                    end
                case 'STATUS_BREAK_TIME'
                    [ind, passed] = statusMilestones.pass(fnCompleteTrials(results));
                    c0 = fnCompleteTrials(results);
                    c1 = fnCorrectTrials(results);
                    rate = c1/c0;
                    s = sprintf('%d/%d complete trials, %.0f%% correct', c0, NumTrials, rate*100);
    
                    % draw text on screen
                    oldTextSize = Screen('TextSize', windowIndex, textSizeForMilestones);
                    DrawFormattedText(windowIndex, s, 'center','center',[1 1 1]);
                    Screen('Flip', windowIndex);
                    Screen('TextSize', windowIndex, oldTextSize);
    
                    % compute detection rate for the last N completed trials
                    stateMgr.transitionTo('BREAK_TIME_WAIT');
                case 'BREAK_TIME_WAIT'
                    if stateMgr.timeInState() >= p.Results.BreakTime
                        Screen('Flip', windowIndex);
                        stateMgr.transitionTo('START');
                    end
                case 'CLEAR_THEN_PAUSE'
                    Screen('Flip', windowIndex);
    
                    % stop tracker recording
                    tracker.offline();
    
                    % free textures, but not gabor textures.
                    Screen('Close', unique(setdiff([texturesA, texturesB], [GaborTex, BkgdTex])));
    
                    stateMgr.transitionTo('WAIT_PAUSE');
                case 'WAIT_PAUSE'
                    % the only way out is to use space bar when paused.
                    if bPausePending
                        fprintf(1, 'Paused. Hit spacebar to resume.\n');
                        bPausePending = false;
                    end
                case 'DONE'
    
                    % save data, again
                    save(outputFilename, 'results');
                    fprintf('\n*** Results saved in output file %s\n', outputFilename);
                
                    experimentElapsedTime = GetSecs - experimentStartTime;
                    fprintf(1, 'This block took %.1f sec.\n', experimentElapsedTime);
    
                    % This will cause us to exit the state loop!
                    bQuit = true;
    
                otherwise
                    error('Unhandled state %s\n', stateMgr.Current);
            end
        end
        if bAbortBlockset
            fprintf('Abort blockset here.\n');
            break;
        end
    end
    % % save data, again
    % save(outputFilename, 'results');
    % fprintf('\n*** Results saved in output file %s\n', outputFilename);
    % 
    % experimentElapsedTime = GetSecs - experimentStartTime;
    % fprintf(1, 'This block took %.1f sec.\n', experimentElapsedTime);
    
end

function [keyPressed, keyCode,  tDown, tUp] = checkKbdQueue(kbindex)

    keyPressed = false;
    keyCode = 0;
    tDown = -1;
    tUp = -1;
    bquit = false;
    
    % Fetch events until a key is released.
    % This could theoretically miss one, if called while it was held down.
    
     while ~bquit && KbEventAvail(kbindex) 
        [event, ~] = KbEventGet(kbindex);
        if event.Pressed
            tDown =  event.Time;
        else
            tUp = event.Time;
            keyCode = event.Keycode;
            bquit = true;
            keyPressed = true;
        end
     end
end

% function saveResultsAndCleanup(folder, base, trials, results)
%     % horzcat, but for tables
%     combined_results=[trials, results];
%     filename=fullfile(folder, [base, char(datetime('now', 'Format', '-yyyyMMdd-HHmm')), '.mat']);
%     save(filename, 'combined_results');
%     cleanup;
% end



% PortAudio and eye tracker should be handled by objects, not here.
function cleanup
    Screen('CloseAll');
    ListenChar(1);
    ShowCursor;
end

