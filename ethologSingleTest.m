function [results] = ethologSingleTest(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    experimentStartTime = GetSecs;
    

%% Create a parser and parse input arguments
    p = inputParser;
    
    p.addRequired('Trials', @(x) istable(x));
    p.addRequired('Images', @(x) isa(x, 'imageset'));

    % Dimensions is the geometry relative to viewing. Two-element vector 
    % [screenWidth, screenDistance] in real situations, for testing a
    % single value is the Fovx. 
    p.addRequired('ScreenWH', @(x) isempty(x) || (isnumeric(x) && isvector(x) && length(x)==2));
    p.addRequired('ScreenDistance', @(x) isempty(x) || (isnumeric(x) && isscalar(x)));

    imageChangeTypes={'luminance', 'contrast'};
    p.addParameter('ImageChangeType', 'contrast', @(x) any(validatestring(x, imageChangeTypes)));

    p.addParameter('ITI', 0.5, @(x) isscalar(x));   % inter-trial interval.
    p.addParameter('Screen', 0, @(x) isscalar(x));
    p.addParameter('Rect', [], @(x) isempty(x) || (isvector(x) && length(x) == 4));
    p.addParameter('Bkgd', [.5 .5 .5], @(x) isrow(x) && length(x) == 3);

    breakParams = {
        .25, 'You''re done 1/4 of the trials in this block.';
        .5, 'You''re halfway through this block!';
        .75, 'That''s 3/4 the trials in this block. Almost done!'
        }

    p.addParameter('Breaks', true, @(x) islogical(x));

    % djs by default no cues are used. 
    p.addParameter('CueColors', [1, 0, 0; 0, 0, 1]', @(x) size(x,1)==4);
    p.addParameter('CueWidth', 2, @(x) isscalar(x));
    p.addParameter('UseCues', false, @(x) islogical(x));

    p.addParameter('FixptDiam', 1, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('FixptXY', [0,0], @(x) isvector(x) && length(x)==2);
    p.addParameter('FixptColor', [0,0,0], @(x) all(size(x) == [1 3]));  % color should be row vector on cmd line
    p.addParameter('FixptWindowDiam', 3, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('Stim1XY', [-10,0], @(x) isvector(x) && length(x)==2);
    p.addParameter('Stim2XY', [10,0], @(x) isvector(x) && length(x)==2);

    % for threshold tests - implies that "a" stim is a single stim, and "b"
    % stim will be in same position, depending on if GaborTest or
    % CImageTest is set. 
    p.addParameter('Threshold', false, @(x) islogical(x));

    % Specify the test type as 'Contrast' (default - this is the original
    % instance of the expt, where a base image is modified on the fly to 
    % increase its contrast), 'Gabor', or 'Image')

    testTypes = {'Contrast', 'Gabor', 'Image'};
    p.addParameter('ExperimentTestType', 'Contrast', @(x) any(validatestring(x, testTypes)));

    % These are for gabors. The Gabors are only used if GaborTest or 
    % GaborThresh is true,otherwise the parameters here are ignored.
    p.addParameter('GaborSF', 0.05, @(x) x>0);
    p.addParameter('GaborSC', 100, @(x) x>0);

    p.addParameter('SkipSyncTests', 0, @(x) isscalar(x) && (x==0 || x==1));
    p.addParameter('OutputFile', 'etholog_output.mat', @(x) ischar(x));
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
    
    % keyboard index is needed for experimenter controls during the expt.
    % See docs for details.
    p.addParameter('KeyboardIndex', 0, @(x) isscalar(x));

    % Now parse the input arguments
    p.parse(varargin{:});

    % fetch some stuff from the results
    ourVerbosity = p.Results.Verbose;
    images = p.Results.Images;

    % This will determine the "test" type - what is shown as the "B" phase.
    % Contrast is the original usage: trials must have a 'Delta'
    bStimType = validatestring(p.Results.ExperimentTestType, testTypes);

    subjectResponseType = validatestring(p.Results.Response, responseTypes);


    % These are applied to images when "A" texture is made (imageBaseFunc),
    % and when the "B" texture is made (imageChangeFunc). FYI - deal is a
    % function that just passes input to output, so is effectively a NO-OP.
    imageBaseFunc = @deal;
    imageChangeFunc = @deal;
    if strcmp(bStimType, 'Contrast')
        imageBaseFunc = @imageset.contrast;
        imageChangeFunc = @imageset.contrast;
    end


    % Prepare output file name. Make sure an existing file does not get
    % clobbered.
    if isfile(p.Results.OutputFile)
        warning('OutputFile %s already exists. Finding a suitable name...', p.Results.OutputFile);
        [path, base, ext] = fileparts(p.Results.OutputFile);
        [ok, outputFilename] = makeNNNFilename(fullfile(path, [base, '_NNN', ext]));
        if ~ok
            error('Cannot form usable filename using folder %s and basename %s', p.Results.Folder, p.Results.Basename);
        end
    else
        outputFilename = p.Results.OutputFile;
    end
    fprintf('\n*** Using output filename %s\n', outputFilename);




    %% Initialize PTB and associated things
    % PTB defaults
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', p.Results.SkipSyncTests);
    
    % Open window for visual stim
    [windowIndex, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
    
    % create converter for dealing with pixels&degrees 
    % If 2 elements, [screenWidthMM, screenDistanceMM]
    % if single element, [fovX] - testing only
    if ~isempty(p.Results.ScreenWH)
        converter = pixdegconverter(windowRect, p.Results.ScreenWH, p.Results.ScreenDistance);
    else
        converter = pixdegconverter(windowRect, p.Results.Fovx);
    end

    % Kb queue - need to know correct index!
    if ~p.Results.KeyboardIndex
        error('Need to specify keyboard index');
    end
    KbQueueCreate(p.Results.KeyboardIndex);

    % input response device if needed
    if strcmp(subjectResponseType, 'MilliKey')
        if ~p.Results.MilliKeyIndex
            error('If MilliKey used as response device, you must supply the keyboard index with MilliKeyIndex');
        end
        millikey = responder(p.Results.MilliKeyIndex);
    end

    % Init audio - BEFORE the tracker is initialized ()
    beeper = twotonebeeper('OpenSnd', true);

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

    % For taking breaks. We check regardless of whether its been requested.
    milestones = OneShotMilestone([breakParams{:,1}]);


    %% Initialize experimental parameters
    
    stateMgr = statemgr('START', ourVerbosity>0);
    bQuit = false;
    bkgdColor = [.5 .5 .5];

    % Diameter of fixation point/cross in pixels
    fixDiamPix = converter.deg2pix(p.Results.FixptDiam);

    % on-screen position of fixation (center) point. deg2scr converts to
    % screen-pixel values (where 0,0 is upper left corner, y positive down.
    fixXYScr = converter.deg2scr(p.Results.FixptXY);

    % Lines for the fixation "+" sign. The array fixLines has x,y values in
    % columns, one column for each line segment.
    fixLines = [ ...
        fixXYScr(1) + fixDiamPix/2, fixXYScr(2); ...
        fixXYScr(1) - fixDiamPix/2, fixXYScr(2); ...
        fixXYScr(1), fixXYScr(2) + fixDiamPix/2; ...
        fixXYScr(1), fixXYScr(2) - fixDiamPix/2
        ]';
    stim1XYScr = converter.deg2scr(p.Results.Stim1XY);
    stim2XYScr = converter.deg2scr(p.Results.Stim2XY);

    % Fixation window. The rect will be used with the eyetracker to test
    % for looking/not-looking
    fixWindowDiamPix = converter.deg2pix(p.Results.FixptWindowDiam);
    fixWindowRect = CenterRectOnPoint([0 0 fixWindowDiamPix fixWindowDiamPix], fixXYScr(1), fixXYScr(2));
    
    
    % The number of trials to run.
    NumTrials = height(p.Results.Trials);
    itrial = 1;

    % All trial parameters are contained in results. Also put
    % results/timestamps/responses/etc in same table.
    results = p.Results.Trials;

    % start kbd queue now
    KbQueueStart(p.Results.KeyboardIndex);
    ListenChar(-1);

    % Create a cleanup object, that will execute whenever this script ends
    % (even if it crashes). Use it to restore matlab to a usable state -
    % see cleanup() below.
    myCleanupObj = onCleanup(@cleanup);

    % Use this for managing pauses
    bPausePending = false;


    %% Start trial loop
    while ~bQuit && ~strcmp(stateMgr.Current, 'DONE')
        
        
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
                        % we are currently paused. Resume by transitioning
                        % to the START state. Current trial is NOT
                        % repeated.
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
                case KbName('d')
                    % this is for doing drift correct, but only if we are
                    % paused.
                    if strcmp(stateMgr.Current, 'WAIT_PAUSE')
                        % draw fixpt, kick off drift correction
                        Screen('FillRect', windowIndex, bkgdColor);
                        Screen('DrawLines', windowIndex, fixLines, 4, p.Results.FixptColor');
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

                        stateMgr.transitionTo('TRIAL_COMPLETE');
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

                        
                        stateMgr.transitionTo('TRIAL_COMPLETE');
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

                % screen output update
                if (ourVerbosity > -1)
                    switch trial.StimTestType
                        case 1
                            side = 'left';
                        case 2
                            side = 'right';
                        case 0
                            side = 'none';
                    end
                    if strcmp(bStimType, 'Image')
                        fprintf('etholog: trial: %3d\t%s\tchange? %d\n', itrial, side, trial.StimChangeType);
                    elseif strcmp(bStimType, 'Gabor')
                        if trial.StimTestType == trial.StimChangeType
                            sChange = 'YES';
                        else
                            sChange = 'NO';
                        end
                        fprintf('etholog: trial: %3d\t%s\tchange? %s\tdelta %3.0f\n', itrial, side, sChange, trial.Delta);
                    end
                end


                % rects for the textures in trial
                stim1Rect = CenterRectOnPoint(images.rect(trial.Stim1Key), stim1XYScr(1), stim1XYScr(2));
                stim2Rect = CenterRectOnPoint(images.rect(trial.Stim2Key), stim2XYScr(1), stim2XYScr(2));


                texturesA = [0,0];
                texturesB = [0,0];
                
                switch bStimType
                    case {'Contrast'}

                        % This is the original version of the expt, where a
                        % base image is modified with a processing
                        % function, which here will adjust the contrast of
                        % the base for the test image only. 

                        texturesA = [ ...
                            images.texture(windowIndex, trial.Stim1Key, @(x) imageBaseFunc(x, trial.Base)), ...
                            images.texture(windowIndex, trial.Stim2Key, @(x) imageBaseFunc(x, trial.Base))
                            ];

                        % The 'b' textures are shown in the test phase. StimTestType 
                        % is the stim (1=left, 2=right) which appears during test phase.
                        % The other stim is blank.
                        iBaseContrast = trial.Base;
                        switch trial.StimChangeType
                            case 1
                                iTestContrast = trial.Base + trial.Delta;
                            case 0
                                iTestContrast = trial.Base;
                            otherwise
                                error('StimTestType is 1, StimChangeType must be 1 or 0');
                        end
                        switch trial.StimTestType
                            case 1
                                iChangeIndex = 1;
                                iChangeStimKey = trial.Stim1Key;
                                iNoChangeIndex = 2;
                                iNoChangeStimKey = trial.Stim2Key;
                            case 2
                                iChangeIndex = 2;
                                iChangeStimKey = trial.Stim2Key;
                                iNoChangeIndex = 1;
                            otherwise
                                error('StimTestType can only be 1 or 2');
                        end
                        texturesB(iChangeIndex) = images.texture(windowIndex, iChangeStimKey, @(x) imageChangeFunc(x, iTestContrast));
                        if p.Results.Threshold
                            texturesB(iNoChangeIndex) = BkgdTex;
                        else
                            texturesB(iNoChangeIndex) = texturesA(iNoChangeIndex);
                        end
                    case 'Gabor'
                        texturesA = [ ...
                            images.texture(windowIndex, trial.Stim1Key), ...
                            images.texture(windowIndex, trial.Stim2Key)
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

                    case 'Image'

                        % For threshold, show bkgd/img(A), and bkgd/test(B).
                        % For non-threshold, show img/img(A) and bkgd/img(B).
                        switch trial.StimTestType
                            case 1
                                texturesA(1) = images.texture(windowIndex, trial.Stim1Key);
                                if p.Results.Threshold
                                    texturesA(2) = BkgdTex;
                                    texturesB = [images.texture(windowIndex, trial.StimTestKey), texturesA(2)];
                                else
                                  texturesA(2) = images.texture(windowIndex, trial.Stim2Key);
                                  texturesB = [images.texture(windowIndex, trial.StimTestKey), BkgdTex];
                                end
                            case 2
                                texturesA(2) = images.texture(windowIndex, trial.Stim2Key);
                                if p.Results.Threshold
                                    texturesA(1) = BkgdTex;
                                    texturesB = [texturesA(1), images.texture(windowIndex, trial.StimTestKey)];
                                else
                                    texturesA(1) = images.texture(windowIndex, trial.Stim1Key);
                                    texturesB = [BkgdTex, images.texture(windowIndex, trial.StimTestKey)];
                                end
                            otherwise
                                error('StimTestType must be 1 or 2');
                        end
                    otherwise
                        error('Unrecognized value for B stim type (%s)', bStimType);
                end
                stateMgr.transitionTo('DRAW_FIXPT');
                
                % results
                results.Started(itrial) = true;
                results.trialOrder(itrial) = itrial;

                % start tracker recording
                tracker.start_recording();

            case 'DRAW_FIXPT'
                % Draw fixation cross on screen
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawLines', windowIndex, fixLines, 4, p.Results.FixptColor');
                Screen('Flip', windowIndex);

                % Draw cross and box on tracker screen
                tracker.draw_cross(fixXYScr(1), fixXYScr(2), 15);
                tracker.draw_box(fixWindowRect(1), fixWindowRect(2), fixWindowRect(3), fixWindowRect(4), 15);

                stateMgr.transitionTo('WAIT_ACQ');
            case 'WAIT_ACQ'
                % no maximum here, could go forever
                % djs - a pending pause is honored here. 
                if bPausePending
                    stateMgr.transitionTo('CLEAR_THEN_PAUSE');
                elseif tracker.is_in_rect(fixWindowRect)
                    stateMgr.transitionTo('WAIT_FIX');
                end
            case 'WAIT_FIX'
                if bPausePending
                    stateMgr.transitionTo('CLEAR_THEN_PAUSE');
                elseif stateMgr.timeInState() > trial.FixationTime
                    stateMgr.transitionTo('DRAW_A');
                elseif ~tracker.is_in_rect(fixWindowRect)
                    stateMgr.transitionTo('FIXATION_BREAK_EARLY');
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
                Screen('DrawTextures', windowIndex, texturesA, [], [stim1Rect;stim2Rect]');
                if p.Results.UseCues
                    Screen('FrameRect', windowIndex, p.Results.CueColors, [stim1Rect;stim2Rect]', p.Results.CueWidth);
                end
                Screen('DrawLines', windowIndex, fixLines, 4, p.Results.FixptColor');

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
                Screen('DrawLines', windowIndex, fixLines, 4,p.Results.FixptColor');
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
                else
                    Screen('DrawTextures', windowIndex, texturesB, [], [stim1Rect;stim2Rect]');
                end                    
                if p.Results.UseCues
                    Screen('FrameRect', windowIndex, p.Results.CueColors, [stim1Rect;stim2Rect]', p.Results.CueWidth);
                end
                Screen('DrawLines', windowIndex, fixLines, 4, p.Results.FixptColor');
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
                        if results.iResp(itrial) == trial.StimChangeType
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

                % screen output update
                if (ourVerbosity > -1)
                    if results.iResp(itrial)==1
                        sresp = 'LEFT CHANGE';
                    elseif results.iResp(itrial)==2
                        sresp = 'RIGHT CHANGE';
                    elseif results.iResp(itrial)==0
                        sresp = 'NO CHANGE';
                    else
                        sresp = 'NO RESPONSE';
                    end
                    if results.iResp(itrial) == results.StimChangeType(itrial)
                        scorr = 'CORRECT';
                    else
                        scorr = 'INCORRECT';
                    end

                    if strcmp(bStimType, 'Image')
                        fprintf('etholog: trial: %3d\t%s\tchange? %d\tresponse: %s\tcorrect? %s\n', itrial, side, trial.StimChangeType, sresp, scorr);
                    elseif strcmp(bStimType, 'Gabor')
                        if trial.StimTestType == trial.StimChangeType
                            sChange = 'YES';
                        else
                            sChange = 'NO';
                        end
                        fprintf('etholog: trial: %3d\t%s\tchange? %s\tdelta %3.0f\tresponse: %s\tcorrect? %s\n', itrial, side, sChange, trial.Delta, sresp, scorr);
                    end
                end
                
                % increment trial
                itrial = itrial + 1;
                if itrial > NumTrials
                    % do stuff for being all done like write output file
                    stateMgr.transitionTo('DONE');
                else
                    % check if a pause is pending
                    if bPausePending
                        stateMgr.transitionTo('WAIT_PAUSE');
                    else
                        % check if its time to take a break
                        if p.Results.Breaks && milestones.check(itrial/NumTrials)
                            stateMgr.transitionTo('BREAK_TIME');
                        else
                            stateMgr.transitionTo('WAIT_ITI');
                        end
                    end
                end

                % free textures, but not gabor textures.
                Screen('Close', unique(setdiff([texturesA, texturesB], [GaborTex, BkgdTex])));
                
            case 'WAIT_ITI'
                if stateMgr.timeInState() >= p.Results.ITI
                    stateMgr.transitionTo('START');
                end
            case 'BREAK_TIME'
                % do nothing yet
                stateMgr.transitionTo('WAIT_ITI');

                % % figure out which break we're on
                % ind = milestones.pass(itrial/NumTrials)
                % if isempty(ind)
                %     % This shouldn't happen! 
                %     stateMgr.transitionTo('START');
                % else
                %     % draw text on screen

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
                % no-op
            otherwise
                error('Unhandled state %s\n', stateMgr.Current);
        end
    end

    % save data, again
    save(outputFilename, 'results');
    fprintf('\n*** Results saved in output file %s\n', outputFilename);

    experimentElapsedTime = GetSecs - experimentStartTime;
    fprintf(1, 'This block took %.1f sec.\n', experimentElapsedTime);
    
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
