function cclab = helper_confi()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

% Eyelink settings
dummymode_EYE = true; %  for Eyelink;
dummymode_milliKey = true; % keep it false; milliKey works only on Linux and I haven't finished coding it yet. 

obs_dist = 30; % my laptop (30 cm); my desktop (45 cm); % CenterforNeuroscience (56 cm)
screenWidth = 21; % my laptop (21 cm); my desktop (40 cm);

screenSize = [800 600]; % [x y]; if x=0 and y=0 it is full screen. 
screenNumber = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

numRepeats = 2; % how many times to repeat each block?
num_trials = 80; % how many trials must be within each block?
break_between_n = 2000; % break between how many trials? (For 10 seconds)

% Probabilities for each block
probability_matrices = [65 5 5 25; ... 'B1' [A, B, C, NoTarget] 
                      5 65 5 25; ... 'B3' 
                      5 5 65 25; ... 'B5' 
                      ];

% Adjust this value to change the ratio of 'V' events to 'H' events.
v_to_h_ratio = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

% Set the variables
settings.mouse = false;
settings.keyboard = false;
settings.debugging = false;

% Fixation point
fixDim = 1; % ppd
fixDim_el = 20; % ppd; for eyelink

% Gabor properties
n_targets = 3;
contrast = 1;
phase = 0;
numCycles = 1; %  spatial frequency in cycles per degree of visual angle
distanceGabor = 10; % ppd
gaborDim = 5; % ppd
gaborDim_el = 8; % ppd; for eyelink

% Bar properties
lineColor = [1 1 1];
lineWidthPix =7;
linelength = 30;
distanceBar = 10; % ppd


% Variables for durations (Note: milliseconds to seconds)
durations.waitTime_fixation = 200; % ms
durations.duration_fixation = 500; % ms
durations.duration_targetFix = 800; % ms
durations.interTrial_interval = 500; % ms

% max duration of a block
durations.duration_block = 90; % minutes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

% Instructions
opening_message = ['Welcome to our experiment!', ...
    '\n\n Please make an eye movement to the location of target', ...
    '\n with horizontal/vertical orientation,', ...
    '\n after the fixation dot at the center disappears.', ...
    '\n\n Press any key to start.'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

% Outputs
cclab.settings = settings;
cclab.numRepeats = numRepeats;
cclab.num_trials = num_trials;
cclab.screenWidth = screenWidth;
cclab.obs_dist = obs_dist;
cclab.screenSize = screenSize;
cclab.screenNumber = screenNumber;
cclab.opening_message = opening_message; 
cclab.probability_matrices = probability_matrices;
cclab.v_to_h_ratio = v_to_h_ratio;
cclab.break_between_n = break_between_n;
fixationDot.fixDim = fixDim;
fixationDot.fixDim_el = fixDim_el;
gaborProperties.n_targets = n_targets;
gaborProperties.contrast = contrast;
gaborProperties.phase = phase;
gaborProperties.numCycles = numCycles;
gaborProperties.distanceGabor = distanceGabor;
gaborProperties.gaborDim = gaborDim;
gaborProperties.gaborDim_el = gaborDim_el;
barProperties.lineColor= lineColor;
barProperties.lineWidthPix = lineWidthPix;
barProperties.linelength = linelength;
barProperties.distanceBar = distanceBar; % ppd

cclab.fixationDot = fixationDot;
cclab.gaborProperties = gaborProperties;
cclab.barProperties = barProperties;
cclab.durations = durations;
cclab.dummymode_EYE = dummymode_EYE;
cclab.dummymode_milliKey = dummymode_milliKey;

end