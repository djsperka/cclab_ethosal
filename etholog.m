function [] = etholog(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


%% deal with input arguments
    p = inputParser;
    p.addParameter('Screen', 0, @(x) isscalar(x));
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
    p.addParameter('Bkgd', [.5 .5 .5], @(x) isrow(x) && length(x) == 3);
    p.addParameter('Name', 'demo', @(x) ischar(x) && length(x)<9 && ~isempty(x));
    p.addParameter('Out', 'out', @(x) isdir(x));
    p.addParameter('Fovx', nan, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('NumTrials', inf, @(x) isscalar(x));
    p.addParameter('ImageRoot', '', @(x) ischar(x) && isdir(x));
    p.addParameter('Response', 'Saccade', @(x) ischar(x));
    p.parse(varargin{:});

    % Now load the expt config, then do a couple of checks
    cclab = load_local_config();
    if isnan(p.Results.Fovx)
       if any(~isfield(cclab, {'ScreenWidthMM', 'EyeDistMM'}))
           error('local config must have dimensions unless Fovx is in args');
       end
    end
    
    % Create a cleanup object, that will execute whenever this script ends
    % (even if it crashes). Use it to restore matlab to a usable state -
    % see cleanup() below.
    myCleanupObj = onCleanup(@cleanup);
    
    % Init ptb, set preferences. 
    % arg == 0 : AssertOpenGL
    % arg == 1 : also KbName('UnifyKeyNames')
    % arg == 2 : also setcolor range 0-1, must use PsychImaging('OpenWindow') 
    PsychDefaultSetup(2);
    Screen('Preference', 'Verbosity', cclab.Verbosity);
    Screen('Preference', 'VisualDebugLevel', cclab.VisualDebugLevel);
    Screen('Preference', 'SkipSyncTests', cclab.SkipSyncTests);
    
    % Open window for visual stim
    [windowIndex, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
    [windowCenterPixX windowCenterPixY] = RectCenter(windowRect);
    
    % create converter for dealing with pixels&degrees 
    if isnan(p.Results.Fovx)
        converter = pixdegconverter(windowRect, cclab.ScreenWidthMM, cclab.EyeDistMM);
    else
        converter = pixdegconverter(windowRect, p.Results.Fovx);
    end
    
    % Kb queue using default keyboard. TODO: might need to allow an ind arg
    [ind, ~, ~] = GetKeyboardIndices();
    kbindex = ind(1);
    KbQueueCreate(kbindex);

    % Init audio
    
    beeper = twotonebeeper();

    % init eye tracker. 
    
    tracker = eyetracker(cclab.dummymode_EYE, p.Results.Name, windowIndex);
    
    % load images
    images = imageset(p.Results.ImageRoot);
    
    %% Now start the experiment. 
    
    state = 'START';
    tStateStarted = GetSecs;
    bQuit = false;
    itrial = 1;
    bkgdColor = [.5 .5 .5];
    
    % Fixation point and stim parameters. TODO: These are either from config or command line
    % Derive other stuff from this below. 
    fixDiamDeg = 1;
    fixXYDeg = [0 0];
    fixColor = [1 0 0];
    stim1XYDeg = [-10 0];
    stim2XYDeg = [10 0];
    fixWindowDiamDeg = 3;

    % aforementioned conversions, to be used below. Note that stim rect is
    % generated on the fly, in case of different sizes. 
    fixDiamPix = converter.deg2pix(fixDiamDeg);
    fixRect = [0 0 fixDiamPix fixDiamPix]; 
    fixXYScr = converter.deg2scr(fixXYDeg);
    stim1XYScr = converter.deg2scr(stim1XYDeg);
    stim2XYScr = converter.deg2scr(stim2XYDeg);
    fixWindowDiamPix = converter.deg2pix(fixWindowDiamDeg);
    fixWindowRect = CenterRectOnPoint([0 0 fixWindowDiamPix fixWindowDiamPix], fixXYScr(1), fixXYScr(2));
    
    
    % The number of trials to run. Unless you set 'NumTrials' on command
    % line, we run all trials in cclab.trials. 
    NumTrials = min(height(cclab.trials), p.Results.NumTrials);
    
    % start kbd queue now
    KbQueueStart(kbindex);
    ListenChar(-1);
    
    while ~bQuit && ~strcmp(state, 'DONE')
        
        
        % any keys pressed? 
        [keyPressed, keyCode,  ~, ~] = checkKbdQueue(kbindex);
        if keyPressed
            switch keyCode
                case KbName('space')
                    % pause OR UNpause
                    if strcmp(state, 'WAIT_PAUSE')
                        % we are currently paused. Resume by transitioning
                        % to the START state. Current trial is NOT
                        % repeated.
                        state = 'TRIAL_COMPLETE';
                        tStateStarted = GetSecs;
                        fprintf('Resume after pause.\n');
                    else
                        % not paused, so we now stop current trial, clear
                        % screen. If there is output, the output from this
                        % trial will have to be flushed. TODO. 
                        Screen('FillRect', windowIndex, bkgdColor);
                        Screen('Flip', windowIndex);
                        state = 'WAIT_PAUSE';
                        tStateStarted = GetSecs;
                        fprintf('Paused.\n');
                    end
                case KbName('q')
                        % trial will have to be flushed. TODO. 
                        Screen('FillRect', windowIndex, bkgdColor);
                        Screen('Flip', windowIndex);
                        state = 'DONE';
                        tStateStarted = GetSecs;
                        fprintf('Quit from kbd.\n');
                otherwise
                    fprintf('Keys:\n<space> - toggle pause\n\n');
            end
        end

                    
        switch upper(state)
            case 'START'
                % get textures ready for this trial
                key1 = [ cclab.trials.Type1(itrial) '/' cclab.trials.FName{itrial} ];
                key2 = [ cclab.trials.Type2(itrial) '/' cclab.trials.FName{itrial} ];
                tex1a = images.texture(windowIndex, key1);
                tex2a = images.texture(windowIndex, key2);
                stim1Rect = CenterRectOnPoint(images.rect(key1), stim1XYScr(1), stim1XYScr(2));
                stim2Rect = CenterRectOnPoint(images.rect(key2), stim2XYScr(1), stim2XYScr(2));

                switch cclab.trials.Change(itrial)
                    case 1
                        tex1b = images.texture(windowIndex, key1, cclab.trials.ChangeContrast(itrial));
                        tex2b = tex2a;
                    case 2
                        tex1b = tex1a;
                        tex2b = images.texture(windowIndex, key2, cclab.trials.ChangeContrast(itrial));
                    case 0
                        tex1b = tex1a;
                        tex2b = tex2a;
                    otherwise
                        error('Change can only be 0,1, or 2.');
                end
                fprintf('START trial %d images %s %s change %d %f\n', itrial, key1, key2, cclab.trials.Change(itrial), cclab.trials.ChangeContrast(itrial));
                state = 'DRAW_FIXPT';
                tStateStarted = GetSecs;
            case 'DRAW_FIXPT'
                % fixpt only
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_ACQ';
                tStateStarted = GetSecs;
            case 'WAIT_ACQ'
                % no maximum here, could go forever
                [x y] = tracker.eyepos();
                if IsInRect(x, y, fixWindowRect)
                    state = 'WAIT_FIX';
                    tStateStarted = GetSecs;
                end
            case 'WAIT_FIX'
                WaitSecs(2.0);
                state = 'DRAW_A';
                tStateStarted = GetSecs;
            case 'DRAW_A'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawTextures', windowIndex, [tex1a tex2a], [], [stim1Rect;stim2Rect]');
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_A';
                tStateStarted = GetSecs;
            case 'WAIT_A'
                if GetSecs - tStateStarted >= cclab.trials.SampTime
                    state = 'DRAW_AB';
                    tStateStarted = GetSecs;
                end
            case 'DRAW_AB'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_AB';
                tStateStarted = GetSecs;
            case 'WAIT_AB'
                if GetSecs - tStateStarted >= cclab.trials.GapTime
                    state = 'DRAW_B';
                    tStateStarted = GetSecs;
                end
            case 'DRAW_B'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawTextures', windowIndex, [tex1b tex2b], [], [stim1Rect;stim2Rect]');
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_B';
                tStateStarted = GetSecs;
            case 'WAIT_B'
                if GetSecs - tStateStarted >= cclab.trials.TestTime
                    state = 'DRAW_BKGD';
                    tStateStarted = GetSecs;
                end
            case 'DRAW_BKGD'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('Flip', windowIndex);
                state = 'WAIT_RESPONSE';
                tStateStarted = GetSecs;
            case 'WAIT_RESPONSE'
                response = 0;
                switch p.Results.Response
                    case 'Saccade'
                        sac = tracker.saccade([stim1Rect;stim2Rect]');
                        % We should ensure that the rectangles cannot
                        % overlap!
                        if any(sac)
                            response = find(sac);
                        end
                    case 'None'
                    case 'Device'
                end
                if response || (GetSecs - tStateStarted) >= cclab.trials.RespTime(itrial)
                    state = 'TRIAL_COMPLETE';
                    tStateStarted = GetSecs;
                    if response == cclab.trials.Change(itrial)
                        fprintf('Correct response\n');
                        beeper.correct();
                    elseif response < 0
                        fprintf('No response\n');
                        beeper.incorrect();
                    else
                        fprintf('Correct response\n');
                        beeper.incorrect();
                    end
                end
            case 'TRIAL_COMPLETE'
                itrial = itrial + 1;
                if itrial > NumTrials
                    % do stuff for being all done like write output file
                    state = 'DONE';
                    tStateStarted = GetSecs;
                else
                    state = 'WAIT_ITI';
                    tStateStarted = GetSecs;
                end
            case 'WAIT_ITI'
                if GetSecs - tStateStarted >= cclab.ITI
                    state = 'START';
                    tStateStarted = GetSecs;
                end
            case {'WAIT_PAUSE', 'DONE'}
                % no-op here, the only way out is to use space bar when paused.
            otherwise
                error('Unhandled state %s\n', state);
        end
    end
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



% PortAudio and eye tracker should be handled by objects, not here.
function cleanup
    Screen('CloseAll');
    ListenChar(1);
    ShowCursor;
end
