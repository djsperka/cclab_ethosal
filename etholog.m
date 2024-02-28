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
    [window, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
    
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
    
    tracker = eyetracker(cclab.dummymode_EYE, p.Results.Name, window);
    
    %% load images
    WaitSecs(2.0);
    
    %% Now start the experiment. 
    
    state = 'START';
    tStateStarted = GetSecs;
    bQuit = false;
    
    while ~bQuit && ~strcmp(state, 'DONE')
        
        switch upper(state)
            case 'START'
                state = 'DRAW1';
                tStateStarted = GetSecs;
            case 'DRAW1'
                % fixpt only
                Screen('FillRect', window);
                
        
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
