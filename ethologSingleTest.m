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
    subjectResponseType = validatestring(p.Results.Response, responseTypes);
    imageChangeType = validatestring(p.Results.ImageChangeType, imageChangeTypes);
    switch imageChangeType
        case 'luminance'
            imageBaseFunc = @imadd;
            imageChangeFunc = @imadd;
        case 'contrast'
            imageBaseFunc = @imageset.contrast;
            imageChangeFunc = @imageset.contrast;
        otherwise
            error('imageChangeType %s not recognized.', imageChangeType);
    end    

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
                        stateMgr.transitionTo('TRIAL_COMPLETE');
                    end
                case KbName('s')
                    % this is for getting into camera setup. Should be able
                    % to re-calibrate from here. Not sure about drift
                    % correction.
                    if strcmp(stateMgr.Current, 'WAIT_PAUSE')
                        fprintf('Entering camera setup. Hit ExitSetup to return to trials.\n');
                        tracker.do_tracker_setup();
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

                % textures for this trial. The 'a' textures (tex1a, tex2a)
                % are shown first.
                tex1a = images.texture(windowIndex, trial.Stim1Key, @(x) imageBaseFunc(x, trial.Base));
                tex2a = images.texture(windowIndex, trial.Stim2Key, @(x) imageBaseFunc(x, trial.Base));
                stim1Rect = CenterRectOnPoint(images.rect(trial.Stim1Key), stim1XYScr(1), stim1XYScr(2));
                stim2Rect = CenterRectOnPoint(images.rect(trial.Stim2Key), stim2XYScr(1), stim2XYScr(2));

                % The 'b' textures are shown in the test phase. StimTestType 
                % is the stim (1=left, 2=right) which appears during test phase.
                % The other stim is blank.
                switch trial.StimTestType
                    case 1
                        % Left stim will appear. Will it change?
                        switch trial.StimChangeType
                            case 1
                                c = trial.Base + trial.Delta;
                            case 0
                                c = trial.Base;
                            otherwise
                                error('StimTestType is 1, StimChangeType must be 1 or 0');
                        end
                        tex1b = images.texture(windowIndex, trial.Stim1Key, @(x) imageChangeFunc(x, c));
                        tex2b = images.texture(windowIndex, 'BKGD');
                    case 2
                        % Right stim will appear. Will it change?
                        switch trial.StimChangeType
                            case 2
                                c = trial.Base + trial.Delta;
                            case 0
                                c = trial.Base;
                            otherwise
                                error('StimTestType is 2, StimChangeType must be 2 or 0');
                        end
                        tex1b = images.texture(windowIndex, 'BKGD');
                        tex2b = images.texture(windowIndex, trial.Stim2Key, @(x) imageChangeFunc(x, c));
                    otherwise
                        error('StimTestType can only be 1 or 2');
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
                Screen('DrawTextures', windowIndex, [tex1a tex2a], [], [stim1Rect;stim2Rect]');
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
                Screen('DrawTextures', windowIndex, [tex1b tex2b], [], [stim1Rect;stim2Rect]');
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
%                 stateMgr.transitionTo('WAIT_B');
%             case 'WAIT_B'
%                 if stateMgr.timeInState() >= trial.TestTime
%                     stateMgr.transitionTo('START_RESPONSE');
%                 elseif ~tracker.is_in_rect(fixWindowRect)
%                     stateMgr.transitionTo('FIXATION_BREAK_LATE');
%                 end
%             case 'START_RESPONSE'
%                 % clear screen
%                 Screen('FillRect', windowIndex, bkgdColor);
%                 [ results.tBoff(itrial) ] = Screen('Flip', windowIndex);
%                 stateMgr.transitionTo('WAIT_RESPONSE_WITH_B');
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
                    fprintf('Response in %s\n', stateMgr.Current);
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
                                % still waiting for response, but clear screen
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


                if (ourVerbosity > -1)
                    fprintf('etholog: trial %d pair %s test %d chgtype %d resp %d delta %f\n', itrial, results.StimPairType(itrial), results.StimTestType(itrial), results.StimChangeType(itrial), results.iResp(itrial), results.Delta(itrial));
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
                        stateMgr.transitionTo('WAIT_ITI');
                    end
                end

                % free textures
                Screen('Close', unique([tex1a, tex2a, tex1b, tex2b]));
                
            case 'WAIT_ITI'
                if stateMgr.timeInState() >= p.Results.ITI
                    stateMgr.transitionTo('START');
                end
            case 'CLEAR_THEN_PAUSE'
                Screen('Flip', windowIndex);

                % stop tracker recording
                tracker.offline();

                % free textures
                Screen('Close', unique([tex1a, tex2a, tex1b, tex2b]));

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
