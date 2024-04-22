# cclab_ethosal
Ethological salience expt

## window

Its useful to be able to quickly create a window on screen. This function lets you specify the dimensions of the window, and where on your desktop you want it. 
Below, it creates an 800x600 window at the center of the right-hand side of screen 0. (See docs for AlignRect for last two args).

```
>> [w, wrect] = makeWindow([800, 600], 0, 'center', 'right');
```

Close the window with **sca** or **Screen('CloseAll')**. 

If the window is open, the value of w can be used for testing imagesets (see below). 


## imageset

This is an imageset loaded for bw images using CONTRAST as the changing property. The 'OnLoad' function is @deal, which does nothing. 

```
>> imgbw=imageset('/home/dan/work/cclab/images/eth/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bw-texture'}, 'OnLoad', @deal)
```

Alternative, using simple clamp method.

```
>> lumbw=imageset('/Users/dan/cclab/images/ethosal/Babies', 'Subfolders', {'H', 'bw'; 'L', 'bwtexture'}, 'OnLoad', @(I) squeezeclampimage(I, [0,225]));
```

To display a stimulus in the center of a window (with window pointer *w*), call the *flip()* method:

```
>> imgbw.flip(w, 'H/N71');
```


## Generate trials

Generate trials for contrast change

```
>> baseContrast = .7;
>> deltas = [0, .1, .2, .3];
>> numberOfImages = 5; % number of trials = numberOfImages * length(deltas)
>> trials=generateThreshBlock(imgbw.BalancedFileKeys, numberOfImages, 'HL', baseContrast, deltas, 1);
```

Generate trials for luminance change

```
baseLumArg = 0;
lumDeltas = [0 10 20];
trials=generateThreshBlock(lumbw.BalancedFileKeys, numberOfImages, 'HL', baseLumArg, lumDeltas, 1);
```


## Run

```
results=etholog(trials, imgbw, [600, 1000], 'ImageChangeType', 'contrast', 'EyelinkDummyMode', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Screen', 0, 'Rect', [1520 400 1920 700])
```

## Beeper

I made a helper class to encapsulate the sound(s) used for correct and incorrect. Should be able to test this easily - see below. The hardware should be properly handled when the beeper object is cleared or deleted. 


```
% Create beeper that uses 0.25s tone of 800Hz "correct" tone, and 350Hz "incorrect" tone.
>> beeper = twotonebeeper();
>> beeper.correct();  % plays 800Hz tone for 0.25s.
>> beeper.incorrect(); % plays 350Hz tone for 0.25s.

% create beeper with different frequencies and duration.
>> beeper = twotonebeeper('Correct', 2500, 'Incorrect', 400, 'Duration', .5)
>> beeper.correct() % plays 2500Hz tone for 0.5s.
>> beeper.incorrect() % plays 400Hz tone for 0.5s.
```

