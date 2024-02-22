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
    p.parse(varargin{:});
    
    fprintf('Input name: %s\n', p.Results.Name);
    fprintf('Background color %f %f %f\n', p.Results.Bkgd(1), p.Results.Bkgd(2), p.Results.Bkgd(3)); 
    fprintf('Screen %d\n', p.Results.Screen);
    
    % verify output folder existence.
    if ~isdir(p.Results.Out)
        error('Output folder ''%s'' not found', p.Results.Out);
    end
    outputMatFilename = fullfile(p.Results.Out, sprintf('%s-%s.mat', datestr(now, 'yyyy-mm-dd-HH-MM-SS'), p.Results.Name));
    if isfile(outputMatFilename)
        error('Output file %s already exists', outputMatFilename);
    end
    
    
    cclab = load_local_config();


    %% Init ptb. 
    % arg == 0 : AssertOpenGL
    % arg == 1 : also KbName('UnifyKeyNames')
    % arg == 2 : also setcolor range 0-1 instead of 0-255 (assuming you use
    % PsychImaging('OpenWindow')
    PsychDefaultSetup(2);
    
    %% Init graphics
    Screen('Preference', 'SkipSyncTests', cclab.SkipSyncTests);
    
    % Open and define the window, get width and height
    [window, windowRect] = PsychImaging('OpenWindow', p.Results.Screen, p.Results.Bkgd, p.Results.Rect);
%     [xCenter, yCenter] = RectCenter(windowRect);
%     screenXpixels = xCenter*2;
%     screenYpixels = yCenter*2;

    %% Init sound
    InitializePsychSound(1);

    % Open Psych-Audio port, with the following arguments
    % 1 = sound playback only
    % [] = default sound device
    % 1 = mono output
    % 44100 Hz = sample frequency
    % 2 = number of playback channels (stereo)
    pahandle = PsychPortAudio('Open', [], 1, 1, 44100, 2);

    % Define correct and incorrect response frequencies
    correctFreq = 800; % in Hz
    incorrectFreq = 350; % in Hz

    % Define time
    t = 0:1/44100:0.1; % 0.1 second duration

    % Generate two pure sine wave tones
    correctTone = sin(2 * pi * correctFreq * t);
    incorrectTone = sin(2 * pi * incorrectFreq * t);


end

