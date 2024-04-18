% make a window, get useful variables
% This makes an 800x600 window on the center of the right-hand-size of
% screen. Last two args place the window - see AlignRect()
[w, wrect] = makeWindow([800, 600], 0, 'center', 'right');





% block for contrast, change on left. 
baseContrast = .7;
deltas = [0, .1, .2, .3];
numberOfImages = 5; % number of trials = numberOfImages * length(deltas)
trialsContrast=generateThreshBlock(imgbw.BalancedFileKeys, numberOfImages, 'HL', baseContrast, deltas, 1);

% TEST, dummy mode, saccade response
results=etholog(trialsContrast, imgbw, [600, 1000], 'ImageChangeType', 'contrast', 'EyelinkDummyMode', 1, 'Response', 'Saccade', 'KeyboardIndex', 11);

% TEST, dummy mode, mkey response
kbind = 11;
mkind = 7;
results=etholog(trialsContrast, imgbw, [600, 1000], 'ImageChangeType', 'contrast', 'EyelinkDummyMode', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Screen', 0, 'Rect', [1520 400 1920 700])