% Acknowledgement: https://peterscarfe.com/ptbtutorials.html

%% Notes to myself



% check % Orhan before finalizing.

% be careful about PsychDefaultSetup(2) and Screen('Preference', 'SkipSyncTests', 1);

%% ---------------------------------------------------
% -------------------
%%                           Script starts here ...
%% ----------------------------------------------------------------------

cclab = helper_confi();


% Open dialog box for EyeLink Data file name entry. File name up to 8 characters
prompt = {'Enter subID file name (up to 8 characters)'};

dlg_title = 'Create subID file';
def = {'demo'}; % Create a default edf file name
answer = inputdlg(prompt, dlg_title, 1, def); % Prompt for new EDF file name
% Print some text in Matlab's Command Window if a file name has not been entered
if  isempty(answer)
    fprintf('Session cancelled by user\n')
    error('Session cancelled by user'); % Abort experiment (see cleanup function below)
end
subID = answer{1}; % Save file name to a variable
% Print some text in Matlab's Command Window if file name is longer than 8 characters
if length(subID) > 8
    fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
    error('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)');
end

startTime = tic;

Screen('Preference', 'SkipSyncTests', 1);
KbName('UnifyKeyNames');
Screen('CloseAll');
Eyelink('ShutDown');
%PsychPortAudio('Close');

%----------------------------------------------------------------------
%                           Variables
%----------------------------------------------------------------------

outputLocation = fullfile(pwd, 'outputs_learningAttention');
experiment = 'LA';
img = imread('/Users/xiaomo/Documents/X Lab/Research/WilledAttentionProject/Images/Image2997.bmp');

numRepeats = cclab.numRepeats;
num_trials = cclab.num_trials;
break_between_n = cclab.break_between_n;

% probabilities
probability_matrix = cclab.probability_matrices;
v_to_h_ratio = cclab.v_to_h_ratio;

% Set the variables
settings.mouse = cclab.settings.mouse;
settings.keyboard = cclab.settings.keyboard;
settings.debugging = cclab.settings.debugging;
screenWidth = cclab.screenWidth;
obs_dist = cclab.obs_dist;
screenSize = cclab.screenSize;
screenNumber = cclab.screenNumber;
% blockN = ['B' char(string(block_n))];
blockN = '1';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Instructions
opening_message = cclab.opening_message;

% Fixation Dot
fixationDot = cclab.fixationDot;
fixDim = fixationDot.fixDim;
fixDim_el = fixationDot.fixDim_el;

% Gabor properties
gaborProperties = cclab.gaborProperties;
n_targets = gaborProperties.n_targets;
contrast = gaborProperties.contrast;
phase = gaborProperties.phase;
numCycles = gaborProperties.numCycles;
distanceGabor = gaborProperties.distanceGabor;
gaborDim = gaborProperties.gaborDim;
gaborDim_el = gaborProperties.gaborDim_el;

% Bar presentation
% Define line color (RGB)
barProperties = cclab.barProperties;
lineColor = barProperties.lineColor;
lineWidthPix =barProperties.lineWidthPix;
linelength = barProperties.linelength;
distanceBar = barProperties.distanceBar;

% Define start and end points for bars with different orientations
xCoords_0 = [0 0];
yCoords_0 = [-linelength/2 linelength/2];
% Rotate the second line by 45 degrees
xCoords_45 = yCoords_0/sqrt(2);
yCoords_45 = yCoords_0/sqrt(2);
% Rotate the second line by 45 degrees
rotationAngle = 135;
xCoords_135 = -xCoords_45;
yCoords_135 = yCoords_45;

% load image set
NaturalImage_dir = '/Users/xiaomo/Downloads/Natural/';
dirs = dir(NaturalImage_dir);
dirs=dirs(~ismember({dirs.name},{'.','..','.DS_Store'}));

TextureImage_dir = '/Users/xiaomo/Downloads/Texture/';
for im_i = 1:100
    name = dirs(im_i).name;

    img = imread([NaturalImage_dir, name]);
    Image_natural(im_i,:,:,:) = img;
    img = imread([TextureImage_dir, name]);
    Image_texture(im_i,:,:,:) = img;
end
ImageName(im_i).name=name;


% Variables for durations (Note: milliseconds to seconds)
durations = cclab.durations;
waitTime_fixation = durations.waitTime_fixation * 0.001; % Duration for the grey screen before the fixation
duration_fixation = durations.duration_fixation * 0.001; % Time window for fixating on the fixation point
duration_targetFix = durations.duration_targetFix * 0.001; % Time window for fixating on the target
interTrial_interval = durations.interTrial_interval * 0.001; % Inter-trial interval

duration_block = durations.duration_block; % minutes

% Eyelink settings
dummymode_EYE = cclab.dummymode_EYE;

% MilliKey settings
dummymode_milliKey = cclab.dummymode_milliKey;

%----------------------------------------------------------------------
%                       Basic setups and checks
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Set up variable for output and exp name
parser = inputParser;
parser.addParameter('Output', outputLocation, @ischar);
parser.addParameter('Screen', screenNumber, @(x) isscalar(x));
parser.addParameter('Name', subID, @ischar);
parser.addParameter('Block', blockN, @ischar);
parser.parse;

% Print to check
fprintf('Output %s\n', parser.Results.Output);
fprintf('Screen %d\n', parser.Results.Screen);

% Check output folder
outputFolder = parser.Results.Output;
if ~exist(outputFolder, 'dir')
    % Create output dir
    if mkdir(outputFolder)
        fprintf('Created output folder %s\n', outputFolder);
    else
        fprintf('Cannot create output folder %s\n', outputFolder);
        return;
    end
else
    fprintf("Output folder (%s) already exists, but that's OK\n", outputFolder);
end

% Output dir exists, check data file
outputFolder = parser.Results.Output;
outputMatFilename = [experiment, '_Sub', parser.Results.Name, '_', parser.Results.Block, '_', datestr(now,'dd-mm-yyyy'),'.mat'];
outputMatFullFilename = fullfile(outputFolder, outputMatFilename);
if exist(outputMatFullFilename)
    fprintf('Output mat file (%s) already exists. Move it or change filename.\n', outputMatFullFilename);
    %     return; % Orhan:
end

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
% rand('seed', sum(100 * clock));
RandStream.setGlobalStream(RandStream('mt19937ar','seed', sum(100*clock)));

% Set the screen number to the external secondary monitor if there is one connected
% Get the list of screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when
% two monitors are connected the one without the menu bar is used as
% the stimulus display.  Chosing the display with the highest dislay number is
% a best guess about where you want the stimulus displayed.
screenNumber = parser.Results.Screen;
disp(['Number of Screen is ', num2str(screenNumber)])

% Define colors
white = [1 1 1];
grey = white / 2;
black = [0 0 0];

% sets the depth (in bits) of each pixel
pixelSize = Screen('PixelSize', screenNumber);
% Setting anything else than 2 will be only useful for debugging
numBuffers = 2;

% Open and define the window, get width and height
if sum(screenSize) == 0
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], pixelSize, numBuffers, [], []);
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [0 0 screenSize(1) screenSize(2)], pixelSize, numBuffers, [], []);
end
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
screenXpixels = xCenter*2;
screenYpixels = yCenter*2;

if n_targets == 3
    % shift position
    shift = 0.1;
    yCenter = yCenter+yCenter*shift;
else
    error("Orhan: I haven't coded it for 2 targets yet.")
end

% pixel per cm (ppcm)
ppcm = windowRect(3) / screenWidth;

% Calculate pixels per degree
ppd = 2 * obs_dist * ppcm * tan(pi / 360);

% fixation point for psychtoolbox
tmp_fpr = round(fixDim*ppd/2);
fpr = [-tmp_fpr -tmp_fpr tmp_fpr tmp_fpr];
rect_fixation = [xCenter, yCenter, xCenter, yCenter]+fpr;

% fixation window for eyelink
tmp_fpr_el = round(fixDim_el*ppd/2);
fpr_el = [-tmp_fpr_el -tmp_fpr_el tmp_fpr_el tmp_fpr_el];

rect_fixation_el = [xCenter, yCenter, xCenter, yCenter]+fpr_el;
center_window = rect_fixation_el;

penWidthPixels = 2;  % Change this to control the width of the circle's outline

% Set the text size
Screen('TextSize', window, round(ppd));

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);
disp(['IFI is ', num2str(ifi)])
fudge = (ifi/2); % the fudge factor in ms; allows to give leeway to the flip timestamps.


try
    %----------------------------------------------------------------------
    %                       Keyboard and Mouse information
    %----------------------------------------------------------------------

    % Define the keyboard keys that are listened for.
    escapeKey = KbName('ESCAPE');
    leftKey = KbName('LeftArrow');
    topKey = KbName('UpArrow');
    rightKey = KbName('RightArrow');
    button_potential = [leftKey topKey rightKey];

    % % Hide mouse cursor, disable keyboard
    if settings.mouse == true
        HideCursor(screenNumber);
    end
    if settings.keyboard == true
        ListenChar(-1);
    end

    %----------------------------------------------------------------------
    %                           Eyelink Settings
    %----------------------------------------------------------------------

    width = screenXpixels;
    height = screenYpixels;

    EyelinkInit(dummymode_EYE); % Initialize EyeLink connection
    status = Eyelink('IsConnected');
    if status < 1 % If EyeLink not connected
        dummymode_EYE = 1;
    end

    edfFile = [parser.Results.Name, '_', parser.Results.Block]; % Save file name to a variable
    % Print some text in Matlab's Command Window if file name is longer than 8 characters
    if length(edfFile) > 8
        fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
        cleanup; % Abort experiment (see cleanup function below)
        return
    end

    % Open an EDF file and name it
    failOpen = Eyelink('OpenFile', edfFile);
    if failOpen ~= 0 % Abort if it fails to open
        fprintf('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
        cleanup; %see cleanup function below
        return
    end

    % Get EyeLink tracker and software version
    % <ver> returns 0 if not connected
    % <versionstring> returns 'EYELINK I', 'EYELINK II x.xx', 'EYELINK CL x.xx' where 'x.xx' is the software version
    ELsoftwareVersion = 0; % Default EyeLink version in dummy mode
    [ver, versionstring] = Eyelink('GetTrackerVersion');
    if dummymode_EYE == 0 % If connected to EyeLink
        % Extract software version number.
        [r1 vnumcell] = regexp(versionstring,'.*?(\d)\.\d*?','Match','Tokens'); % Extract EL version before decimal point
        ELsoftwareVersion = str2double(vnumcell{1}{1}); % Returns 1 for EyeLink I, 2 for EyeLink II, 3/4 for EyeLink 1K, 5 for EyeLink 1KPlus, 6 for Portable Duo
        % Print some text in Matlab's Command Window
        fprintf('Running experiment on %s version %d\n', versionstring, ver );
    end
    % Add a line of text in the EDF file to identify the current experimemt name and session. This is optional.
    % If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
    % the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
    preambleText = sprintf('RECORDED BY Psychtoolbox demo %s session name: %s', mfilename, edfFile);
    Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);

    % This script calls Psychtoolbox commands available only in OpenGL-based
    % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
    % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
    % an error message if someone tries to execute this script on a computer without
    % an OpenGL Psychtoolbox
    AssertOpenGL;

    % Select which events are saved in the EDF file. Include everything just in case
    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    % Select which events are available online for gaze-contingent experiments. Include everything just in case
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
    % Select which sample data is saved in EDF file or available online. Include everything just in case
    if ELsoftwareVersion > 3  % Check tracker version and include 'HTARGET' to save head target sticker data for supported eye trackers
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
    else
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end

    % Provide EyeLink with some defaults, which are returned in the structure "el".
    el = EyelinkInitDefaults(window);
    % set calibration/validation/drift-check(or drift-correct) size as well as background and target colors.
    % It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
    % pupil size changes (which can cause a drift in the eye movement data)
    el.calibrationtargetsize = 2; % Outer target size as percentage of the screen
    el.calibrationtargetwidth = 0.7; % Inner target size as percentage of the screen
    el.backgroundcolour = grey; % RGB grey
    el.calibrationtargetcolour = black; % RGB black
    % set "Camera Setup" instructions text colour so it is different from background colour
    el.msgfontcolour = black; % RGB black

    %     % Use an image file instead of the default calibration bull's eye targets.
    %     % Commenting out the following two lines will use default targets:
    %     el.calTargetType = 'image';
    %     el.calImageTargetFilename = [pwd '/' 'fixTarget.jpg'];

    % Set calibration beeps (0 = sound off, 1 = sound on)
    el.targetbeep = 1;  % sound a beep when a target is presented
    el.feedbackbeep = 1;  % sound a beep after calibration or drift check/correction

    % You must call this function to apply the changes made to the el structure above
    EyelinkUpdateDefaults(el);

    % Set display coordinates for EyeLink data by entering left, top, right and bottom coordinates in screen pixels
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
    Eyelink('Command', 'calibration_type = HV5'); % horizontal-vertical 9-points
    % Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
    Eyelink('Command', 'button_function 5 "accept_target_fixation"');
    % Clear Host PC display from any previus drawing
    Eyelink('Command', 'clear_screen 0');

    % Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
    EyelinkDoTrackerSetup(el);

    %----------------------------------------------------------------------
    %                           Sound setup
    %----------------------------------------------------------------------

    % Initialize PsychPortAudio
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

    %----------------------------------------------------------------------
    %                       Gabor information
    %----------------------------------------------------------------------

    % Dimension of the region where will draw the Gabor in pixels
    gaborDimPix = round(ppd*gaborDim);
    gaborDimPix_el = round(ppd*gaborDim_el);

    % Sigma of Gaussian window
    sigma = gaborDimPix / 7;

    % Obvious Parameters
    aspectRatio = 1.0;

    % Spatial Frequency (Cycles Per Pixel)
    % One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
    freq = numCycles / ppd;

    % Build a procedural gabor texture (Note: to get a "standard" Gabor patch
    % we set a grey background offset, disable normalisation, and set a
    % pre-contrast multiplier of 0.5).
    backgroundOffset = [0.5 0.5 0.5 0.0];
    disableNorm = 1;
    preContrastMultiplier = 0.5;
    gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
        backgroundOffset, disableNorm, preContrastMultiplier);


    % Randomise the phase of the Gabors and make a properties matrix.
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];

    % We will update the stimulus on each frame
    waitframes = 1;

    % We choose an arbitary value at which our Gabor will drift
    phasePerFrame = 4 * pi;

    %----------------------------------------------------------------------
    %                              Gabor locations
    %----------------------------------------------------------------------

    r = ppd*distanceGabor;
    r_bar = ppd*distanceBar;

    if n_targets == 3
        theta = [210 90 330];
        x_cartesian = r * cosd(theta);
        y_cartesian = r * sind(theta);

        x_cartesian_bar = r_bar * cosd(theta);
        y_cartesian_bar = r_bar * sind(theta);

        % Define the destination rectangles for Gabors
        nGabor = 3;
        xPos = xCenter + x_cartesian;
        yPos = yCenter - y_cartesian;

        xPos_bar = xCenter + x_cartesian_bar;
        yPos_bar = yCenter - y_cartesian_bar;

        baseRect = [0 0 gaborDimPix gaborDimPix];
        baseRect_el = [0 0 gaborDimPix_el gaborDimPix_el];
        dstRects_gabors = nan(4, 3);
        dstRects_gabors_el = nan(4, 3);
    end

    for i = 1:nGabor
        dstRects_gabors(:, i) = CenterRectOnPointd(baseRect, xPos(i), yPos(i));
        dstRects_gabors_el(:, i) = CenterRectOnPointd(baseRect_el, xPos(i), yPos(i));
    end


    %----------------------------------------------------------------------
    %                               Conditions
    %----------------------------------------------------------------------

    if n_targets == 3

        vert = 0; hori = 90; ori135 = 45; ori45 = 135;

        % Repeat the rows
        expanded_matrix = repmat(probability_matrix, [numRepeats 1]);
        shuffled_prob0 = Shuffle(expanded_matrix, 2);

        %xc edit
        shuffled_prob=shuffled_prob0(1,:);
        shuffled_prob = cat(1,shuffled_prob,[25 25 25 25]);
        for block = 2: size(shuffled_prob0,1)
            shuffled_prob = cat(1, shuffled_prob,shuffled_prob0(block,:) );
            shuffled_prob = cat(1,shuffled_prob,[25 25 25 25]);
        end

        event_codes_sampled = zeros(num_trials, length(shuffled_prob));
        probablity_codes=[];
        for ii = 1:length(shuffled_prob)
            probability_vector = shuffled_prob(ii, :);
            [event_codes_sampled(:, ii),probablity_codes_sampled] = sample_eventCodes(probability_vector, v_to_h_ratio, num_trials);
            probablity_codes = cat(1, probablity_codes, probablity_codes_sampled);
        end

        all_conditions = string(event_codes_sampled(:));
    end

    % Calculate number of trials
    totalNumTrials = length(all_conditions);

    %----------------------------------------------------------------------
    %                       Experimental loop
    %----------------------------------------------------------------------

    % initiate the vectors for results
    isValid_vector      = [];
    condition_vector    = [];
    trialStart_vector   = [];
    fixationOn_vector   = [];
    targetsFix_vector   = [];
    goOn_vector         = [];
    trialEnd_vector     = [];
    RT_vector           = [];
    Bpressed_vector     = {};

    % the current trial
    trial_number        = 0;

    % Define experiment start
    WaitSecs(1);

    % Draw the opening message
    DrawFormattedText(window, opening_message, 'center', 'center', black);
    % Flip to the screen
    Screen('Flip', window);

    if dummymode_milliKey == false
        % Wait for single keystroke:
        % Get device index, use the first one found if more than one
        mkind = cclabGetMilliKeyIndices();
        if isempty(mkind)
            error('No MilliKey devices found');
        end
        ind = mkind(1);
        PsychHID('KbQueueStart', ind);
        iquit = 0;
        while ~iquit
            % Use KbEventAvail to tell if there is anything available.
            while ~iquit && KbEventAvail(ind)
                [event, ~] = KbEventGet(ind);
                if event.Keycode == 37
                    iquit = 1;
                end
            end
            ~iquit && WaitSecs(.1);
        end
        PsychHID('KbQueueStop', ind);
        KbEventFlush(ind);
    else
        KbWait;
    end


    % Priority level
    Priority(topPriorityLevel);

    % Animation loop: we loop for the total number of trials
    while trial_number < totalNumTrials

        %random pick an image
        ImageID = randsample(100,1);
        Imagelocation = randsample(3,3);
        image_nature =  squeeze(Image_natural(ImageID,:,:,:));
        image_texture =  squeeze(Image_texture(ImageID,:,:,:));

        % Advance to the next trial
        trial_number = trial_number +1;

        % halt the script
        [keyIsDown, secs, keyCode] = KbCheck;
        key_pressed = KbName(keyCode);
        if logical(keyIsDown) && strcmp(key_pressed, 'q')
            cleanup;
            fprintf('\nThe researcher halted the script.\n\n');
            error('The researcher halted the script.');
            break
        elseif logical(keyIsDown) && strcmp(key_pressed, 'k')
            sca
            fprintf('\nThe researcher closed the screen.\n\n');
            keyboard % Pause here
        end

        % Define time vectors to avoid array index problem
        isValid_vector(trial_number)        = NaN;
        probability_vector(trial_number,:)  = nan(1,4);
        condition_vector(trial_number)      = NaN;
        Imageloaction_vector(trial_number,:) = nan(1,3);
        ImageID_vector(trial_number)         =NaN;
        targets_orientation(trial_number,:) = nan(1,3);
        target_vector(trial_number)         = NaN;
        trialStart_vector(trial_number)     = NaN;
        fixationOn_vector(trial_number)     = NaN;
        targetsFix_vector(trial_number)     = NaN;
        goOn_vector(trial_number)           = NaN;
        trialEnd_vector(trial_number)       = NaN;
        RT_vector(trial_number)             = NaN;
        Bpressed_vector{trial_number}       = 'NaN';

        button_keyIsDown = false;
        button_RT = NaN;
        button_pressed = 'NaN';

        %----------------------------------------------------------------------
        %                       Next Trial
        %----------------------------------------------------------------------
        event_code = all_conditions{trial_number};
        [orientation_targets, target_idx] = which_condi(event_code, n_targets);
        event_code_d = str2double(event_code);
        prob_code = probablity_codes(trial_number,:);

        %----------------------------------------------------------------------
        %                       Off-Screen Windows
        %----------------------------------------------------------------------
        step_1 = NaN; step_2 = NaN; step_3 = NaN; step_4 = NaN;
        trialStart = NaN; fixationOn = NaN; targetsFix = NaN; trialEnd = NaN;

        %% Step 1
        % Draw a blank screen
        step1_screen = Screen('OpenOffscreenWindow', window, grey, windowRect);
        timing_1 = interTrial_interval-fudge;

        %% Step 2
        step2_screen = Screen('OpenOffscreenWindow', window, grey, windowRect);
        % Draw a fixation point
        Screen('FillOval', step2_screen, black, rect_fixation);
        timing_2 = [waitTime_fixation-fudge, waitTime_fixation+fudge];

        %% Step 3
        % FLip to the vertical retrace rate
        vbl = Screen('Flip', window);
        % We will update the stimulus on each frame
        waitframes = 1;
        % We choose an arbitary value at which our Gabor will drift
        phasePerFrame = 4 * pi;
        %
        propertiesMat_trial = propertiesMat;
        %
        timing_3 = [duration_fixation-fudge, duration_fixation+fudge];

        %% debugging
        if settings.debugging
            disp(' ');
            disp(['Trial Number --> ', num2str(trial_number)]);
            disp(['Condition --> ', event_code]);
            output = debugging(rightKey, escapeKey);
            if output
                cleanup;
            end
        end

        %% Eyelink
        [keyIsDown, ~, keyCode] = KbCheck;
        key_pressed = KbName(keyCode);
        if logical(keyIsDown) && strcmp(key_pressed, 'p')
            % re-calibration
            EyelinkDoTrackerSetup(el);
        end
        % Write TRIALID message to EDF file: marks the start of a trial for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
        Eyelink('Message', 'EVENTCODE %d', event_code_d);
        % Supply the trial number as a line of text on Host PC screen
        Eyelink('Command', 'record_status_message "EVENTCODE %d"', event_code_d);
        % Start recording
        Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode before recording
        Eyelink('StartRecording'); % Start tracker recording
        WaitSecs(0.1); % Allow some time to record a few samples before presenting first stimulus
        % Check which eye is available. Returns 0 (left), 1 (right) or 2 (binocular)
        eyeUsed = Eyelink('EyeAvailable');
        % Get samples from right eye if binocular
        if eyeUsed == 2
            eyeUsed = 1;
        end
        % Perform drift correction
        Eyelink('Command', 'drift_correct_cr_disable = OFF');
        Eyelink('Command', 'online_dcorr_refposn %i,%i', xCenter, yCenter);

        %----------------------------------------------------------------------
        %                       States for the Experimental Design
        %----------------------------------------------------------------------
        all_steps = ["Trial_start", "Fixation_on", "Targets_fix", "The_end", "Repeat_trial" ];
        state = "Trial_start";
        trialInProcess = true;
        while trialInProcess

            % Check that eye tracker is  still recording. Otherwise close and transfer copy of EDF file to Display PC
            err = Eyelink('CheckRecording');
            if(err ~= 0)
                fprintf('EyeLink Recording stopped!\n');
                % Transfer a copy of the EDF file to Display PC
                Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
                Eyelink('CloseFile'); % Close EDF file on Host PC
                Eyelink('Command', 'clear_screen 0'); % Clear trial image on Host PC at the end of the experiment
                WaitSecs(0.1); % Allow some time for screen drawing
                % Transfer a copy of the EDF file to Display PC
                transferFile(dummymode_EYE, edfFile); % See transferFile function below
                cleanup; % Abort experiment (see cleanup function below)
                return
            end

            switch(state)
                %----------------------------------------------------------------------
                %                       Step 1: Trial Start
                %----------------------------------------------------------------------
                case "Trial_start"

                    Screen('DrawTexture', window, step1_screen);
                    Screen('DrawingFinished', window);

                    % Flip to the screen
                    if trial_number == 1
                        step_1 = Screen('Flip', window); % arbitrary fliptime for the first trial
                    else
                        % wait for the inter trial interval
                        step_1 = Screen('Flip', window, step_4 + timing_1);
                    end

                    %  Event code
                    EVENTCODE = '1';

                    % Write message to EDF file to mark the start time of stimulus presentation.
                    Eyelink('Message', ['MYKEYWORD ' EVENTCODE]);
                    % Draw on Eyelink screen
                    Eyelink('command', 'clear_screen %d', 0);
                    Eyelink('command', 'draw_box %d %d %d %d 15', round(rect_fixation_el(1)), ...
                        round(rect_fixation_el(2)), round(rect_fixation_el(3)), ...
                        round(rect_fixation_el(4)));
                    for box = 1:nGabor
                        Eyelink('command', 'draw_box %d %d %d %d 15', round(dstRects_gabors_el(1,box)), ...
                            round(dstRects_gabors_el(2,box)), round(dstRects_gabors_el(3,box)), ...
                            round(dstRects_gabors_el(4,box)));
                    end

                    %----------------------------------------------------------------------
                    %                       Step 2: Fixation On
                    %----------------------------------------------------------------------

                    Screen('DrawTexture', window, step2_screen);
                    Screen('DrawingFinished', window);

                    % Flip to the screen
                    step_2 = Screen('Flip', window, step_1 + timing_2(1));
                    % Timing check
                    if step_2 - step_1 > timing_2(2)
                        fprintf('WARNING! waitTime_fixation is %i. \n', step_2-step_1-timing_2(2));
                    end

                    % Event code
                    EVENTCODE = '2';
                    Eyelink('Message', ['MYKEYWORD ' EVENTCODE]);

                    % Check eyegaze
                    check_howLong = duration_fixation;
                    check_window = center_window;

                    tThen = 0;
                    tNow = GetSecs;
                    while tThen-tNow <= check_howLong
                        [ex, ey] = getEyePos(dummymode_EYE, eyeUsed, window);
                        inside_target = IsInRect(ex, ey, check_window);

                        tThen = GetSecs;
                    end

                    if inside_target
                        state = 'Targets_fix';
                    else
                        state = "Repeat_trial";
                    end

                    %----------------------------------------------------------------------
                    %                       Step 3: Targets Fixation
                    %----------------------------------------------------------------------
                case "Targets_fix"

                    % Check eyegaze
                    check_howLong = duration_targetFix;
                    if target_idx ~= 0
                        check_window = dstRects_gabors_el(:, target_idx)';
                    else
                        check_window = center_window;
                    end

                    tThen = 0;
                    tNow = GetSecs;
                    while tThen-tNow <= check_howLong
                        [ex, ey] = getEyePos(dummymode_EYE, eyeUsed, window);
                        inside_target = IsInRect(ex, ey, check_window);

                        % Check button press
                        if dummymode_milliKey == false
                            % MilliKey
                            mkind = cclabGetMilliKeyIndices();
                            if isempty(mkind)
                                error('No MilliKey devices found');
                            end
                            ind = mkind(1);
                            PsychHID('KbQueueStart', ind);
                            if KbEventAvail(ind)
                                [event, ~] = KbEventGet(ind);
                                button_keyIsDown = true;
                                button_pressed = string(event.Keycode);
                                button_RT = (event.Time - tNow) * 1000;
                                PsychHID('KbQueueStop', ind);
                                KbEventFlush(ind);
                                break;
                            end
                        else
                            [keyIsDown, tButton, keyCode] = KbCheck;
                            if keyIsDown
                                button_pressed = KbName(keyCode);
                                if ismember(button_pressed, {'LeftArrow', 'UpArrow', 'RightArrow'})
                                    button_keyIsDown = true;
                                    button_RT = (tButton - tNow) * 1000;
                                    break;
                                end
                            end
                        end

                        % Draw a fixation point
                        Screen('FrameOval', window, black, rect_fixation, penWidthPixels);

                        % lineCoords=[];
                        for targ_i = 1:length(xPos)
                            clear lineCoords_i
                            if targ_i == Imagelocation(1)
                                Texture = Screen('MakeTexture', window, image_nature);
                            else
                                Texture = Screen('MakeTexture', window, image_texture);
                            end

                            Screen('DrawTextures', window, Texture, [], dstRects_gabors_el(:,targ_i));
                            if orientation_targets(targ_i) ==0
                                lineCoords_x  = xCoords_0;
                                lineCoords_y  = yCoords_0;

                            elseif orientation_targets(targ_i) ==45
                                lineCoords_x  = xCoords_45;
                                lineCoords_y  = yCoords_45;

                            elseif orientation_targets(targ_i) ==135
                                lineCoords_x  = xCoords_135;
                                lineCoords_y  = yCoords_135;
                            end

                            lineCoords = [lineCoords_x; lineCoords_y]+ [xPos_bar(targ_i), xPos_bar(targ_i); yPos_bar(targ_i), yPos_bar(targ_i)];
                            Screen('DrawLines', window, lineCoords,lineWidthPix,lineColor);

                        end

                        Screen('DrawingFinished', window); % Tell PTB that no further drawing commands will follow before Screen('Flip')

                        % Screen('DrawTextures', window, gabortex, [], dstRects_gabors, orientation_targets, [], [], [], [],...
                        %     kPsychDontDoRotation, propertiesMat_trial');

                        % Flip to the screen
                        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
                        if isnan(step_3)
                            step_3 = vbl;
                        end
                        % Update the phase element of the properties matrix
                        propertiesMat_trial(1) = propertiesMat_trial(1) + phasePerFrame;

                        tThen = GetSecs;
                    end

                    if step_3 - step_2 > timing_3(2)
                        fprintf('WARNING! duration_fixation is %i. \n', step_3-step_2-timing_3(2));
                    end

                    % Event code
                    EVENTCODE = event_code;
                    Eyelink('Message', ['MYKEYWORD ' EVENTCODE]);

                    if button_keyIsDown
                        if dummymode_milliKey == false
                            error('TO BE DONE!');
                        else
                            if target_idx ~= 0
                                keyCode = find(keyCode, 1);
                                if keyCode == button_potential(target_idx)
                                    state = 'The_end';
                                    isIt = 'correct';
                                else
                                    state = "Repeat_trial";
                                    isIt = 'incorrect';
                                end
                            else
                                state = "Repeat_trial";
                                isIt = 'incorrect';
                            end
                            fprintf('\tSubject pressed %s. Reaction time is %.2f. The answer is %s.\n', button_pressed, button_RT, isIt);
                        end
                    else
                        if inside_target
                            state = 'The_end';
                            fprintf('\tSubject fixated to the right target.\n');
                        else
                            state = "Repeat_trial";
                            fprintf('\tSubject did not fixated to the right target or pressed any key.\n');
                        end
                    end

                    %----------------------------------------------------------------------
                    %                       Step 4: The end
                    %----------------------------------------------------------------------
                case "The_end"

                    DrawFormattedText(window, '+10', xCenter-tmp_fpr/2, yCenter+tmp_fpr/2, black);
                    step_4 = Screen('Flip', window);

                    PsychPortAudio('FillBuffer', pahandle, [correctTone; correctTone]);
                    % Start audio playback for a brief moment
                    PsychPortAudio('Start', pahandle, 1, 0, 1);
                    % Wait for the audio to finish
                    WaitSecs(0.1);
                    % Stop audio playback
                    PsychPortAudio('Stop', pahandle);

                    % EEG event code
                    EVENTCODE = '10';
                    Eyelink('Message', ['MYKEYWORD ' EVENTCODE]);

                    WaitSecs(0.1); % Add 100 msec of data to catch final events before stopping
                    Eyelink('StopRecording'); % Stop tracker recording
                    isValid = true;
                    trialInProcess = false;

                    %----------------------------------------------------------------------
                    %                         Repeat Trial
                    %----------------------------------------------------------------------
                case "Repeat_trial"

                    DrawFormattedText(window, '+0',  xCenter-tmp_fpr/2, yCenter+tmp_fpr/2, black);
                    step_4 = Screen('Flip', window);

                    PsychPortAudio('FillBuffer', pahandle, [incorrectTone; incorrectTone]);
                    % Start audio playback for a brief moment
                    PsychPortAudio('Start', pahandle, 1, 0, 1);
                    % Wait for the audio to finish
                    WaitSecs(0.1);
                    % Stop audio playback
                    PsychPortAudio('Stop', pahandle);

                    % EEG event code
                    EVENTCODE = '11';
                    Eyelink('Message', ['MYKEYWORD ' EVENTCODE]);

                    WaitSecs(0.1); % Add 100 msec of data to catch final events before stopping
                    Eyelink('StopRecording'); % Stop tracker recording
                    isValid = false;
                    trialInProcess = false;

                otherwise
                    error("Unhandled state %s\n", state);
            end
        end
        % Record the time
        trialStart  = step_1;
        fixationOn  = step_2;
        targetsFix  = step_3;
        trialEnd    = step_4;

        isValid_vector(trial_number)        = isValid;
        condition_vector(trial_number)      = event_code_d;
        probability_vector(trial_number,:)  = prob_code;
        Imageloaction_vector(trial_number,:)      = Imagelocation;
        ImageID_vector(trial_number)      = ImageID;
        targets_orientation(trial_number,:) = orientation_targets;
        target_vector(trial_number)   = target_idx;
        trialStart_vector(trial_number)     = 0; % trialStart-trialStart
        fixationOn_vector(trial_number)     = (fixationOn-trialStart)*1000;
        targetsFix_vector(trial_number)     = (targetsFix-trialStart)*1000;
        trialEnd_vector(trial_number)       = (trialEnd-trialStart)*1000;
        RT_vector(trial_number)             = button_RT;
        Bpressed_vector{trial_number}       = button_pressed;

        % Write the result into data table
        dataTable = table(isValid_vector(1, 1:trial_number)', condition_vector(1, 1:trial_number)', trialStart_vector(1, 1:trial_number)', ...
            fixationOn_vector(1, 1:trial_number)', targetsFix_vector(1, 1:trial_number)',...
            trialEnd_vector(1, 1:trial_number)', RT_vector(1, 1:trial_number)', Bpressed_vector(1, 1:trial_number)', ...
            Imageloaction_vector(1:trial_number,:), ImageID_vector(1, 1:trial_number)',...
            targets_orientation(1:trial_number,:), target_vector(1, 1:trial_number)', probability_vector(1:trial_number,:),...
            'VariableNames', {'Is_valid', 'Event_code', 'Trial_start', 'Fixation_on', 'Targets_fix', ...
            'Trial_end', 'Button_RT', 'Button_Pressed','Imageloaction','ImageID','Targets_Orietnation','TargetID','TargetProbability'});

        % Save the data for each trial
        save(outputMatFullFilename);

        % wait for the inter trial interval
        WaitSecs(interTrial_interval);

        Screen('Close', [step1_screen, step2_screen]);

        fprintf('Progress %d%% --> %d. trial / %d total trial \n', floor(trial_number/totalNumTrials*100), trial_number, totalNumTrials);

        if trial_number > 1 && mod(trial_number, break_between_n) == 0 && trial_number < totalNumTrials
            message_ = 'This is a short 10-second break to rest your eyes. \nPlease continue resting your chin on the chin rest.';
            DrawFormattedText(window, message_, 'center', 'center', black);
            Screen('Flip', window);
            WaitSecs(7);
            message_ = '3...';
            DrawFormattedText(window, message_, 'center', 'center', black);
            WaitSecs(1);
            Screen('Flip', window);
            message_ = '2...';
            DrawFormattedText(window, message_, 'center', 'center', black);
            WaitSecs(1);
            Screen('Flip', window);
            message_ = '1...';
            DrawFormattedText(window, message_, 'center', 'center', black);
            WaitSecs(1);
            Screen('Flip', window);
        end

        currentTime = toc(startTime);
        if currentTime/60 > duration_block % minutes
            break;
        end
    end

    fprintf('\nThis block took %.1f minutes.\n', currentTime/60);

    % % End of the each block
    % if block_n == length(cclab.probability_matrices)
    line4 = 'End of the experiment. Thank you for your participation!';
    % else
    %     line4 = 'End of this block. You can give a break now!';
    % end

    % Exit screen
    line5 = 'Press any key to exit.';
    exit_lines = [line4, '\n\n ', line5];

    Screen('FillRect', window, grey);
    DrawFormattedText(window, exit_lines, 'center', 'center', black);
    Screen('Flip', window);
    % Wait for single keystroke:
    KbStrokeWait;
    writetable(dataTable, [outputMatFullFilename(1:end-4) '.csv'], 'Delimiter', ',') % save as .csv
    Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
    WaitSecs(1); % Allow some time before closing and transferring file
    Eyelink('CloseFile'); % Close EDF file on Host PC
    WaitSecs(1); % Allow some time after closing
    % Transfer a copy of the EDF file to Display PC
    transferFile(dummymode_EYE, edfFile); % See transferFile function below

catch
    % Print error message and line number in Matlab's Command Window
    psychrethrow(psychlasterror);
end
cleanup;

% Cleanup function used throughout the script above
function cleanup
try
    Screen('CloseAll'); % Close window if it is open
    Eyelink('ShutDown');
    PsychPortAudio('Close');
    ppdev_mex('Close',1) % Close the parallelport
catch
    warning('Problem during `cleanup` function.');
end
ListenChar(1); % Restore keyboard output to Matlab
ShowCursor; % Restore mouse cursor
Priority(0);
if ~IsOctave; commandwindow;  % Bring Command Window to front
end
end

% Function to get eyegaze coordinates
function [ex, ey] = getEyePos(dummymode, eyeUsed, window)
if (dummymode == 1)
    [ex, ey] = GetMouse(window);
else
    evt = Eyelink('NewestFloatSample');
    ex = evt.gx(eyeUsed+1);
    ey = evt.gy(eyeUsed+1);
end
end

% Function to double-check the conditions
function output = debugging(rightKey, escapeKey)
while 1
    [keyIsDown, ~, keyCode] = KbCheck;
    keyCode = find(keyCode, 1);

    if keyIsDown
        if keyCode == rightKey
            output = false;
            break
        elseif keyCode == escapeKey
            output = true;
            break
        end
        KbReleaseWait;
    end
end
end

function transferFile(dummymode, edfFile)
try
    if dummymode == 0 % If connected to EyeLink

        fprintf('Receiving data file ''%s.edf''\n', edfFile); % Print some text in Matlab's Command Window

        % Transfer EDF file to Host PC
        status = Eyelink('ReceiveFile', edfFile);

        % Check if EDF file has been transferred successfully and print file size in Matlab's Command Window
        if status > 0
            fprintf('EDF file size: %.1f KB\n', status/1024); % Divide file size by 1024 to convert bytes to KB
        end
    else
        fprintf('No EDF file saved in Dummy mode\n');
    end
catch % Catch a file-transfer error and print some text in Matlab's Command Window
    fprintf('Problem receiving data file ''%s''\n', edfFile);
    psychrethrow(psychlasterror);
end
end


function [orientation_targets, target_idx] = which_condi(event_code, n_targets)

if n_targets == 3

    % vert = 0; hori = 90; ori135 = 45; ori45 = 135;
    V = 0; H = 90; x = 45; y = 135;
    orientation_codes = {'V', 'H', 'x', 'y'};
    angle_values = {V, H, x, y};
    % Create a map from orientation codes to angle values
    angle_map = containers.Map(orientation_codes, angle_values);

    % Define the event codes and the corresponding potential orientations
    event_codes = {'110', '111', '112', '113', '114', '115', '116', '117', '118', '119', '120', '121', '222', '223', '224', '225', '226', '227'};
    potential_orientations = {'Vxy', 'Vyx', 'Hxy', 'Hyx', 'xVy', 'yVx', 'xHy', 'yHx', 'xyV', 'yxV', ...
        'xyH', 'yxH', 'xxy', 'xyx', 'yxx', 'yyx', 'yxy', 'xyy'};
    % Create a map from event codes to potential orientations
    code_map = containers.Map(event_codes, potential_orientations);

    % Use the map to find the potential orientation
    potential_orientation = code_map(event_code);

    % Convert the potential orientation into a list of angles
    orientation_targets = [];
    for i = 1:length(potential_orientation)
        orientation_code = potential_orientation(i);
        angle = angle_map(orientation_code);
        orientation_targets = [orientation_targets, angle];
    end

    % The corresponding target locations
    target_locations = {'left', 'left', 'left', 'left', 'top', 'top', 'top', 'top', 'right', 'right', 'right', 'right', ...
        'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN'};
    % Create a map from event codes to target locations
    target_map = containers.Map(event_codes, target_locations);
    % Use the map to find the target location
    target_location = target_map(event_code);
    if target_location(1) == 'l'
        target_idx = 1;
    elseif target_location(1) == 't'
        target_idx = 2;
    elseif target_location(1) == 'r'
        target_idx = 3;
    else
        target_idx = 0;
    end

end
end

function [event_codes, probablity_codes] = sample_eventCodes(probability_vector, v_to_h_ratio, num_trials)

% Ratios
go_to_stop_ratio = sum(probability_vector(1:3))/100;
left_to_top_to_right_ratio = probability_vector(1:3)/100; % Adjust this array to change the ratios for left, top, right target locations.

% Number of Go and Stop trials
num_go = round(go_to_stop_ratio * num_trials);
num_stop = num_trials - num_go;

% Number of left, top, right target locations
num_left = round(left_to_top_to_right_ratio(1) * num_go);
num_top = round(left_to_top_to_right_ratio(2) * num_go);
num_right = num_go - num_left - num_top;

% Adjusted number of 'V' and 'H' events
num_left_V = round(num_left * v_to_h_ratio);
num_left_H = num_left - num_left_V;
num_top_V = round(num_top * v_to_h_ratio);
num_top_H = num_top - num_top_V;
num_right_V = round(num_right * v_to_h_ratio);
num_right_H = num_right - num_right_V;

% Event codes with V and H
event_codes_go_left_V = [110, 111];
event_codes_go_left_H = [112, 113];
event_codes_go_top_V = [114, 115];
event_codes_go_top_H = [116, 117];
event_codes_go_right_V = [118, 119];
event_codes_go_right_H = [120, 121];
event_codes_stop = 222:227;

% Repeat event codes to match number of trials and randomize
event_codes_go_left_V = event_codes_go_left_V(randi([1 length(event_codes_go_left_V)], 1, num_left_V));
event_codes_go_left_H = event_codes_go_left_H(randi([1 length(event_codes_go_left_H)], 1, num_left_H));
event_codes_go_top_V = event_codes_go_top_V(randi([1 length(event_codes_go_top_V)], 1, num_top_V));
event_codes_go_top_H = event_codes_go_top_H(randi([1 length(event_codes_go_top_H)], 1, num_top_H));
event_codes_go_right_V = event_codes_go_right_V(randi([1 length(event_codes_go_right_V)], 1, num_right_V));
event_codes_go_right_H = event_codes_go_right_H(randi([1 length(event_codes_go_right_H)], 1, num_right_H));
event_codes_stop = event_codes_stop(randi([1 length(event_codes_stop)], 1, num_stop));

% Concatenate all event codes
event_codes = [event_codes_go_left_V, event_codes_go_left_H, event_codes_go_top_V, event_codes_go_top_H, event_codes_go_right_V, event_codes_go_right_H, event_codes_stop];
targ_codes = [3*ones(size(event_codes_go_left_V)),3*ones(size(event_codes_go_left_H)),2*ones(size(event_codes_go_top_V)),2*ones(size(event_codes_go_top_H)),...
    1*ones(size(event_codes_go_right_V)),1*ones(size(event_codes_go_right_H)), -1*ones(size(event_codes_stop)) ];


% Randomly shuffle the event codes
[event_codes,ind]= Shuffle(event_codes);
target_codes = targ_codes(ind);
probablity_codes = ones(num_trials,1)*reshape(probability_vector,1,4);

end




%% Orhan Soyuhos, 2023