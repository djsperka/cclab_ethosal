# cclab_ethosal
Ethological salience expt

## how to run

### Generate trials

In order to generate trials, you must load an imageset (or at least have a list of the file keys for the image set you will use). When loading, provide a params argument for the folder mapping you will use. See [here](#imageset) for more.

The imageset used for ethosal is loaded differently, depending on the type of trial.

#### Generate trials for contrast-changed images

```
>> local_ethosal
>> [blocks, inputArgs, parsedResults] = generateEthBlocksImg(img.BalancedFileKeys, [40,40], 'FolderKeys',{'H';'L'},'TestKeys',{'h';'l'},NumBlocks=2);
Block 1 has 320 elements
Block 2 has 320 elements
>> S.blocks=blocks;
>> S.imagesetName=img.Name;
>> S.imagesetParamsFunc=img.ParamsFunc;
>> save(fullfile(ethDataRoot,'input','mimg_exp_40img-dlt20-x8-A.mat'), '-struct', 'S');
```



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

Generate trials for gabor threshold

```
trials=generateThreshBlockGabor(img.BalancedFileKeys, 30, [2,4,6,8],'TestTime',0.1);
```

Generate trials for processed images. 

Several things are hard-coded in this script, including 

```
    deltas = [-20;-10;0;10;20];
```

The imageset uses a newfangled params.m file in its Root folder. That file
maps the folders to folder keys. The images are divided into two groups, 
'Texture' and 'Natural'. Each of those groups is further divided into a contrast
reduced image. The folder names indicate the contrast change from the original.

In this thresh test, we will change the contrasts both up and down from a 
central base value. To accomplish this, the subfolders are mapped to a set of 
characters so that their alphabetical order is also the order of increasing contrast.

```
function Y = params()
    Y.Subfolders={ ...
    'F','Nature/HistMatch0';'G','Nature/HistMatch10';'H','Nature/HistMatch20';'I','Nature/HistMatch30';'J','Nature/HistMatch40';...
    'O','Texture/HistMatch0';'P','Texture/HistMatch10';'Q','Texture/HistMatch20';'R','Texture/HistMatch30';'S','Texture/HistMatch40'
    };
end
```

So, the letters F,G,H,I,J represent contrast differences -20,-10,0,10,20. Similarly for low salience images, 
the letters O,P,Q,R,S represent -20,-10,0,10,20 (it wouldn't have worked with L as the center, then we'd have
overlapped).

Here's how to generate

```
trials=generateThreshBlockProcImage(img.BalancedFileKeys, 5)
```


### About the keyboard index

The keyboard index is used to get input from the experimenter.
Keystrokes can pause, quit, maybe even other stuff. 

One must first solve the mystery of what your keyboard index is.
Use this command:

```
>> [ind names allinf] = GetKeyboardIndices();
```


**MAC**
On my macbook, this command gives a single index, a device with the
name 'Apple Internal Keyboard / Trackpad'. I use this index with my
macbook (testing only) and it works fine. 


**LINUX (ubuntu 22.04.4)**

On the linux desktop, use the command ***xinput -list***:
```
dan@bucky:~/git/cclab_ethosal$ xinput -list
⎡ Virtual core pointer                    	id=2	[master pointer  (3)]
⎜   ↳ Virtual core XTEST pointer              	id=4	[slave  pointer  (2)]
⎜   ↳ Logitech USB Trackball                  	id=10	[slave  pointer  (2)]
⎣ Virtual core keyboard                   	id=3	[master keyboard (2)]
    ↳ Virtual core XTEST keyboard             	id=5	[slave  keyboard (3)]
    ↳ Power Button                            	id=6	[slave  keyboard (3)]
    ↳ Power Button                            	id=7	[slave  keyboard (3)]
    ↳ Sleep Button                            	id=8	[slave  keyboard (3)]
    ↳ Dell Dell USB Keyboard                  	id=9	[slave  keyboard (3)]
```

Your keyboard is listed as one of the "slave keyboard" entries. In particular, the name listed for your keyboard, 
here it is **Dell Dell USB Keyboard**, is important. The ***id=#*** values are NOT the same as the indices used in PTB. 
You need to run the ***GetKeyboardIndices*** command in Matlab.

```
>> [ind names allinf] = GetKeyboardIndices();
```

This is the contents of 'names':
```
>> names

names =

  1×5 cell array

    {'Virtual core XTEST key…'}    {'Power Button'}    {'Power Button'}    {'Sleep Button'}    {'Dell Dell USB Keyboard'}
```

Your task is to decide which of the 'names' best describes your
keyboard. In my case, the name matches exactly what is listed in the
***xinput*** command output, so I use the index at position 5 in the 
ind() array (from GetKeyboardIndices): for me ind(5) is 7, and I use
7 as my keyboard index. 

### Run

```
results=etholog(trials, imgbw, [600, 1000], 'ImageChangeType', 'contrast', 'EyelinkDummyMode', 1, 'Response', 'MilliKey', 'MilliKeyIndex', mkind, 'KeyboardIndex', kbind, 'Screen', 0, 'Rect', [1520 400 1920 700])
```


## Utilities

### eyetracker

Encapsulation of Eyelink tracker. Boilerplate code is hidden, this class initializes tracker in the same way as all the Eyelink examples, suitable for use in most lab situations. 

```
% for use with subject, set to 1 for mouse (not same as Eyelink "mouse mode")
% When using dummy mode (==1), calls to eyepos() will return the current MOUSE position on screen.
% This is independent of the Eyelink's mouse simulation mode! 
dummy_mode = 0;  

% dimensions of screen and screen dist, in mm
wh = [600,300];
dist = 900;

% name is an 8 character filename (without extension) for the EDF file.
% I think this is a throwback to the DOS days, when filenames had to
% be 8.3 chars.
edfname = 'myedf001';

% Now make the object, and initiate "Camera Setup"
% 'windowIndex' is the PTB window index. Yes, you have to have an open window
% to be able to use this object!
tracker=eyetracker(dummy_mode, wh, dist, edfname, windowIndex);

% Alternative call, skipping over the Camera Setup step
tracker=eyetracker(dummy_mode, wh, dist, edfname, windowIndex, 'DoSetup', false);

% Any time you are RECORDING (in the Eyelink sense), you can observe eye position. Thus,
% you have to call this to start the tracker recording:

tracker.start_recording()

% Either of these stops recording. The Eyelink uses the term "offline" for when the tracker is not recording. 
% In other words, you only need to call one of these - they're the same.

tracker.offline();
tracker.stop_recording();

% Getting/testing eye position
[eyeX, eyeY] = tracker.eyepos();

% Is the current eye position inside this rectangle?
tf = tracker.is_in_rect(rect_in_screen_pixels);

% Is the current eye position inside one of a group of rectangles?
% Each rectangle is a COLUMN in the array, which must be 4xN:
% The return is a row vector, each element corresponds to the
% rect in that column
S = tracker.saccade(rectangles_in_columns);

% Once you're done and you want to fetch the edf file (optional), call this.
% This is the simplest call, the file is copied to the current (matlab) folder, with the same
% filename as that used when the eyetracker object was created.

tracker.receive_file();

% If you want to use the same filename, but move it in to a different folder. The second arg
% tells if the first arg was a pathname (1) or filename (with or without a path, 0).

tracker.receive_file('/home/cclab/data', 1);

% To give it a folder and a different name

tracker.receive_file('/home/cclab/data/newname.edf', 0);

```

### makeWindow
Its useful to be able to quickly create a window on screen. This function lets you specify the dimensions of the window, and where on your desktop you want it. 
Below, it creates an 800x600 window at the center of the right-hand side of screen 0. (See docs for AlignRect for last two args).

```
>> [w, wrect] = makeWindow([800, 600], 0, 'center', 'right');
```

Close the window with **sca** or **Screen('CloseAll')**. 

If the window is open, the value of w can be used for testing imagesets (see below). 


### imageset

An imageset is a class that represents a set of images in a folder. The folder may have subfolders where 
the same set of images is repeated in each subfolder, with different processing. One folder may hold a full color image, 
another may have a black and white version, another may have a texturized version of the same image, and so on.

An imageset is loaded from a root folder. Images should be in subfolders under the root. A 'Subfolders' argument specifies the 
subfolders to load, and what "folder key" to use for images in that folder. The full key for a given image is a string consisiting 
of its "folder key", followed by a slash "/", followed by the image file base name. 

The 'Subfolders' arg is a Nx2 cell array, where the first column are the folder keys, and the second column are the subfolders, 
relative to the base folder, where images are found. This arg can be passed on the command line with `'Subfolders, { ... }, ...'`. 
A more convenient method is to store a function in a file of the same name (e.g. params() in params.m) stored in the *root folder* 
of the imageset. 

The name of the params function is the second arg to imageset(). 

When generating threshold trials using the processed images, the params file looks like this:

```
function Y = params()
    Y.Subfolders={ ...
    'F','Nature/HistMatch0';...
    'G','Nature/HistMatch10';...
    'H','Nature/HistMatch20';...
    'I','Nature/HistMatch30';...
    'J','Nature/HistMatch40';...
    'O','Texture/HistMatch0';...
    'P','Texture/HistMatch10';...
    'Q','Texture/HistMatch20';...
    'R','Texture/HistMatch30';...
    'S','Texture/HistMatch40'
    };
end
```



The simpler imageset have a pair of folders. This is the Babies/ folder we used for the earlier black and white test:

```
function Y = params()
    Y.Subfolders={ 'H','bw'; 'L','bw-texture'}; 
end
```




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

### Beeper

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

