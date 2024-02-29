function [] = etholog(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


%% deal with input arguments
    p = inputParser;
    p.addParameter('Screen', 0, @(x) isscalar(x));
    p.addParameter('Rect', [], @(x) isvector(x) && length(x) == 4);
    p.addParameter('Bkgd', [.5 .5 .5], @(x) isrow(x) && length(x) == 3);
    p.addParameter('Name', 'demo', @(x) ischar(x) && length(x)<9 && ~isempty(x));
    p.addParameter('Out', 'out', @(x) ischar(x));
    p.addParameter('Fovx', nan, @(x) isscalar(x) && isnumeric(x));
    p.addParameter('NumTrials', inf, @(x) isscalar(x));
    p.parse(varargin{:});
    
%     fprintf('Input name: %s\n', p.Results.Name);
%     fprintf('Background color %f %f %f\n', p.Results.Bkgd(1), p.Results.Bkgd(2), p.Results.Bkgd(3)); 
%     fprintf('Screen %d\n', p.Results.Screen);
    
    % verify output folder existence.
    if ~isdir(p.Results.Out)
        error('Output folder ''%s'' not found', p.Results.Out);
    end
    outputMatFilename = fullfile(p.Results.Out, sprintf('%s-%s.mat', datestr(now, 'yyyy-mm-dd-HH-MM-SS'), p.Results.Name));
    if isfile(outputMatFilename)
        error('Output file %s already exists', outputMatFilename);
    end
    
    
    %% Now load the expt config, then do a couple of checks
    cclab = load_local_config();
    if isnan(p.Results.Fovx)
       if any(~isfield(cclab, {'ScreenWidthMM', 'EyeDistMM'}))
           error('local config must have dimensions unless Fovx is in args');
       end
    end
    

    %% Cleanup object
    myCleanupObj = onCleanup(@cleanup);
    
    %% Init ptb. 
    % arg == 0 : AssertOpenGL
    % arg == 1 : also KbName('UnifyKeyNames')
    % arg == 2 : also setcolor range 0-1, must use PsychImaging('OpenWindow') 
    PsychDefaultSetup(2);
    Screen('Preference', 'Verbosity', cclab.Verbosity);
    Screen('Preference', 'VisualDebugLevel', cclab.VisualDebugLevel);
    Screen('Preference', 'SkipSyncTests', cclab.SkipSyncTests);
    
    %% Open window for visual stim
    [windowIndex, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
    [windowCenterPixX windowCenterPixY] = RectCenter(windowRect);
    
    %% create converter and a keyboard queue for later. 
    if isnan(p.Results.Fovx)
        converter = pixdegconverter(windowRect, cclab.ScreenWidthMM, cclab.EyeDistMM);
    else
        converter = pixdegconverter(windowRect, p.Results.Fovx);
    end
    
    % Kb queue using default keyboard. TODO: might need to allow an ind arg
    [ind, ~, ~] = GetKeyboardIndices();
    kbindex = ind(1);
    KbQueueCreate(kbindex);

    %% Init audio
    
    beeper = twotonebeeper();

    %% init eye tracker
    
    tracker = eyetracker(cclab.dummymode_EYE, p.Results.Name, windowIndex);
    
    %% load images
    images = imageset(cclab.ImageFiles);
    
    %% Now start the experiment. 
    
    state = 'START';
    tStateStarted = GetSecs;
    bQuit = false;
    itrial = 1
    bkgdColor = [.5 .5 .5];
    
    % Fixation point and stim parameters. TODO: These are either from config or command line
    % Derive other stuff from this below. 
    fixDiamDeg = 5;
    fixXYDeg = [0 0];
    fixColor = [1 0 0];
    stim1XYDeg = [-10 0];
    stim2XYDeg = [10 0];

    % aforementioned conversions, to be used below. Note that stim rect is
    % generated on the fly, in case of different sizes. 
    fixDiamPix = converter.deg2pix(fixDiamDeg);
    fixRect = [0 0 fixDiamPix fixDiamPix]; 
    fixXYScr = converter.deg2scr(fixXYDeg);
    stim1XYScr = converter.deg2scr(stim1XYDeg);
    stim2XYScr = converter.deg2scr(stim2XYDeg);
    
    % The number of trials to run. Unless you set 'NumTrials' on command
    % line, we run all trials in cclab.trials. 
    NumTrials = min(height(cclab.trials), p.Results.NumTrials);
    
    while ~bQuit && ~strcmp(state, 'DONE')
        
        switch upper(state)
            case 'START'
                % get textures ready for this trial
                fprintf('START trial %d\n', itrial);
                tex1a = images.texture(windowIndex, cclab.trials.Img1(itrial));
                tex2a = images.texture(windowIndex, cclab.trials.Img2(itrial));
                stim1Rect = CenterRectOnPoint(images.rect(cclab.trials.Img1(itrial)), stim1XYScr(1), stim1XYScr(2));
                stim2Rect = CenterRectOnPoint(images.rect(cclab.trials.Img2(itrial)), stim2XYScr(1), stim2XYScr(2));
                disp(stim1Rect);
                disp(stim2Rect);

                switch cclab.trials.Change(itrial)
                    case 1
                        tex1b = images.texture(windowIndex, cclab.trials.Img1(itrial), cclab.trials.ChangeContrast(itrial));
                        tex2b = tex2a;
                    case 2
                        tex1b = tex1a;
                        tex2b = images.texture(windowIndex, cclab.trials.Img2(itrial), cclab.trials.ChangeContrast(itrial));
                    case 0
                        tex1b = tex1a;
                        tex2b = tex2a;
                    otherwise
                        error('Change can only be 0,1, or 2.');
                end
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
                % testing - just wait 2.0sec and print something
                fprintf('in WAIT_ACQ...');
                WaitSecs(2.0);
                fprintf('done.\n');
                state = 'WAIT_FIX';
                tStateStarted = GetSecs;
            case 'WAIT_FIX'
                fprintf('in WAIT_FIX...');
                WaitSecs(2.0);
                fprintf('done.\n');
                state = 'DRAW_A';
                tStateStarted = GetSecs;
            case 'DRAW_A'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawTextures', windowIndex, [tex1a tex2a], [], [stim1Rect;stim2Rect]');
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_AB';
                tStateStarted = GetSecs;
            case 'WAIT_AB'
                if GetSecs - tStateStarted >= cclab.trials.SampTime
                    state = 'DRAW_B';
                    tStateStarted = GetSecs;
                end
            case 'DRAW_B'
                Screen('FillRect', windowIndex, bkgdColor);
                Screen('DrawTextures', windowIndex, [tex1b tex2b], [], [stim1Rect;stim2Rect]');
                Screen('FillOval', windowIndex, fixColor, CenterRectOnPoint(fixRect, fixXYScr(1), fixXYScr(2)));
                Screen('Flip', windowIndex);
                state = 'WAIT_RESPONSE';
                tStateStarted = GetSecs;
            case 'WAIT_RESPONSE'
                if GetSecs - tStateStarted >= cclab.trials.RespTime
                    state = 'TRIAL_COMPLETE';
                    tStateStarted = GetSecs;
                end
            case 'TRIAL_COMPLETE'
                itrial = itrial + 1;
                if itrial > NumTrials
                    % do stuff for being all done like write output file
                    state = 'DONE';
                    tStateStarted = GetSecs;
                else
                    state = 'START';
                    tStateStarted = GetSecs;
                end
            otherwise
                error('Unhandled state %s\n', state);
        end
                    
                
        
    end

    
    % 
    

    end



    
function [tflip] = drawScreen(cfg, wp, fixpt_xy)
    Screen('FillRect', wp, cfg.background_color);
    if ~isempty(fixpt_xy)
        Screen('FillOval', wp, cfg.fixation_color, CenterRectOnPoint(cfg.fixpt_rect, fixpt_xy(1), fixpt_xy(2)))
    end
    tflip = Screen('Flip', wp);
end



% Cleanup function used throughout the script above
function cleanup
    fprintf('in cleanup()\n');
    try
        Screen('CloseAll'); % Close window if it is open
        % see eyetracker.m 'delete' 
        % Eyelink('ShutDown');
        PsychPortAudio('Close');
    catch
        warning('Problem during `cleanup` function.');
    end
    ListenChar(1); % Restore keyboard output to Matlab
    ShowCursor; % Restore mouse cursor
end
