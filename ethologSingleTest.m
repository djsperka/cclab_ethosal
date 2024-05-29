function [results] = ethologSingleTest(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


    experimentStartTime = GetSecs;
    

%% deal with input arguments
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
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
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
    
    % The keyboard index is used to get input from the experimenter.
    % Keystrokes can pause, quit, maybe even other stuff. 
    % 
    % One must first solve the mystery of what your keyboard index is.
    % Use this command:
    % >> [ind names allinf] = GetKeyboardIndices();
    %
    % MAC
    %
    % On my macbook, this command gives a single index, a device with the
    % name 'Apple Internal Keyboard / Trackpad'. I use this index with my
    % macbook (testing only) and it works fine. 
    %
    %
    % LINUX (ubuntu 22.04.4)
    %
    % On my linux desktop, here is the output of xinput -list:
    %
    %     dan@bucky:~/git/cclab_ethosal$ xinput -list
    %     ⎡ Virtual core pointer                    	id=2	[master pointer  (3)]
    %     ⎜   ↳ Virtual core XTEST pointer              	id=4	[slave  pointer  (2)]
    %     ⎜   ↳ Logitech USB Trackball                  	id=10	[slave  pointer  (2)]
    %     ⎣ Virtual core keyboard                   	id=3	[master keyboard (2)]
    %         ↳ Virtual core XTEST keyboard             	id=5	[slave  keyboard (3)]
    %         ↳ Power Button                            	id=6	[slave  keyboard (3)]
    %         ↳ Power Button                            	id=7	[slave  keyboard (3)]
    %         ↳ Sleep Button                            	id=8	[slave  keyboard (3)]
    %         ↳ Dell Dell USB Keyboard                  	id=9	[slave  keyboard (3)]
    %
    % Your keyboard is listed as one of the "slave keyboard" entries. 
    % When I run (in Matlab) GetKeyboardIndices:
    %
    % >> [ind names allinf] = GetKeyboardIndices();
    % 
    % This is the contents of 'names':
    %     >> names
    %     
    %     names =
    %     
    %       1×5 cell array
    %     
    %         {'Virtual core XTEST key…'}    {'Power Button'}    {'Power Button'}    {'Sleep Button'}    {'Dell Dell USB Keyboard'}
    % 
    % Your task is to decide which of the 'names' best describes your
    % keyboard. In my case, the name matches exactly what is listed in the
    % 'xinput' command output, so I use the index at position 5 in the 
    % ind() array (from GetKeyboardIndices): for me ind(5) is 7, and I use
    % 7 as my keyboard index. 
    %

    p.addParameter('KeyboardIndex', 0, @(x) isscalar(x));

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


    % Init ptb, set preferences. 
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
    
    %% Now start the experiment. 
    
    stateMgr = statemgr('START', ourVerbosity>0);
    bQuit = false;
    bkgdColor = [.5 .5 .5];

    % Convert values for display. Note that stim rect is
    % generated on the fly, in case of different sizes. 
    fixDiamPix = converter.deg2pix(p.Results.FixptDiam);
    fixXYScr = converter.deg2scr(p.Results.FixptXY);
    % row 1 = x values, row2 = y values
    % first (second) column: start(end) of first segment
    % and so on
    fixLines = [ ...
        fixXYScr(1) + fixDiamPix/2, fixXYScr(2); ...
        fixXYScr(1) - fixDiamPix/2, fixXYScr(2); ...
        fixXYScr(1), fixXYScr(2) + fixDiamPix/2; ...
        fixXYScr(1), fixXYScr(2) - fixDiamPix/2
        ]';
    stim1XYScr = converter.deg2scr(p.Results.Stim1XY);
    stim2XYScr = converter.deg2scr(p.Results.Stim2XY);
    fixWindowDiamPix = converter.deg2pix(p.Results.FixptWindowDiam);
    fixWindowRect = CenterRectOnPoint([0 0 fixWindowDiamPix fixWindowDiamPix], fixXYScr(1), fixXYScr(2));
    
    
    % The number of trials to run. Unless you set 'NumTrials' on command
    % line, we run all trials in cclab.trials. 
    NumTrials = height(p.Results.Trials);
    results = p.Results.Trials;

%     % All results go here. We put the trial parameters in as well.
%     variableNames = { 'Started', 'trialOrder', 'tAon', 'tAoff', 'tBon', 'tBoff', 'tResp', 'iResp' };
%     variableTypes = {'logical', 'int32', 'double', 'double', 'double', 'double', 'double', 'int32' };
%     results = [p.Results.Trials, table('Size', [ NumTrials, length(variableNames)], 'VariableNames', variableNames, 'VariableTypes', variableTypes)];

    tqueue = CQueue(num2cell([1:NumTrials]));
    itrial = tqueue.pop();


    % start kbd queue now
    KbQueueStart(p.Results.KeyboardIndex);
    ListenChar(-1);

    % Create a cleanup object, that will execute whenever this script ends
    % (even if it crashes). Use it to restore matlab to a usable state -
    % see cleanup() below.
    myCleanupObj = onCleanup(@cleanup);

    % Use this for managing pauses
    bPausePending = false;

    % Count the number of times we recycle missed trials
    recycleCount = 0;
    recycleCountMax = 2;

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
                otherwise
                    if (ourVerbosity > -1); fprintf('Keys:\n<space> - toggle pause\n\n');end
            end
        end

                    
        switch stateMgr.Current
            case 'START'
                % get a struct with just trial params.  
                trial = table2struct(results(itrial, :));
                if (ourVerbosity > -1)
                    fprintf('etholog: START trial %d images %s %s chgtype %d delta %f\n', itrial, trial.Stim1Key, trial.Stim2Key, trial.StimChangeType, trial.Delta);
                end

                % get textures ready for this trial
                whos('trial.Stim1Key')
                tex1a = images.texture(windowIndex, trial.Stim1Key, @(x) imageBaseFunc(x, trial.Base));
                tex2a = images.texture(windowIndex, trial.Stim2Key, @(x) imageBaseFunc(x, trial.Base));
                stim1Rect = CenterRectOnPoint(images.rect(trial.Stim1Key), stim1XYScr(1), stim1XYScr(2));
                stim2Rect = CenterRectOnPoint(images.rect(trial.Stim2Key), stim2XYScr(1), stim2XYScr(2));

                % StimTestType is the stim (1=left, 2=right) which appears
                % during test phase.
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
                        if (ourVerbosity > -1); fprintf('etholog: Change L by %d\n', trial.Delta); end
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
                        if (ourVerbosity > -1); fprintf('etholog: Change R by %d\n', trial.Delta); end
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
                % fixpt only
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawLines', windowIndex, fixLines, 4, p.Results.FixptColor');
                Screen('Flip', windowIndex);

                % draw fixpt and box
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
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('Flip', windowIndex);
                stateMgr.transitionTo('FIXATION_BREAK_EARLY_WAIT');
            case 'FIXATION_BREAK_EARLY_WAIT'
                if stateMgr.timeInState() > trial.FixationBreakEarlyTime
                    stateMgr.transitionTo('DRAW_FIXPT');
                end
            case 'DRAW_A'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawTextures', windowIndex, [tex1a tex2a], [], [stim1Rect;stim2Rect]');
                if p.Results.UseCues
                    Screen('FrameRect', windowIndex, p.Results.CueColors, [stim1Rect;stim2Rect]', p.Results.CueWidth);
                end

                % Note - convert fixpt from oval to cross. 
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
                stateMgr.transitionTo('START_RESPONSE');
            case 'START_RESPONSE'
                if strcmp(subjectResponseType, 'MilliKey')
                    millikey.start();
                end
                stateMgr.transitionTo('WAIT_RESPONSE');
            case 'WAIT_RESPONSE'
                response = 0;
                tResp = 0;

               
                % TODO - more accuracy w/r/to the response time would be
                % good. That will change when we nail down what to use as a
                % response device. 
                
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
                if isResponse || stateMgr.timeInState() >= trial.RespTime
                    stateMgr.transitionTo('TRIAL_COMPLETE');
                    if (ourVerbosity > -1); fprintf('etholog: TRIAL_COMPLETE response %d dt %f\n', response, tResp - stateMgr.StartedAt); end
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
                elseif ~tracker.is_in_rect(fixWindowRect)
                    stateMgr.transitionTo('FIXATION_BREAK_LATE');
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

                % Get next trial. If the trial queue his been emptied, then
                % re-populate it with the indices of trials that have not
                % yet been completed. 

                
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

%                 if ~tqueue.isempty()
%                     itrial = tqueue.pop();
%                 else
%                     if recycleCount==recycleCountMax
%                         stateMgr.transitionTo('DONE');
%                     else
%                         recycleCount = recycleCount + 1;
%                         logCompleted = results.Started & results.tResp>0;
%                         notCompleted = find(~logCompleted);
%                         if isempty(notCompleted)
%                             stateMgr.transitionTo('DONE');
%                         else
%                             tqueue = CQueue(num2cell(notCompleted));
%                             itrial = tqueue.pop();
%                             % check if a pause is pending
%                             if bPausePending
%                                 stateMgr.transitionTo('WAIT_PAUSE');
%                             else
%                                 stateMgr.transitionTo('WAIT_ITI');
%                             end
%                         end
%                     end
%                 end

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
