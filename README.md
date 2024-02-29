# cclab_ethosal
Ethological salience expt

## Run

```
>> etholog('Screen', 0, 'Rect', [0 0 800 600], 'NumTrials', 2, 'Fovx', 45);
```
This will run the first two trials taken from cclab.trials. If the #NumTrials# arg is omitted, all trials are run. 

The expt is displayed in a window on your screen 0 with the rectangle shown. This runs on my laptop, and should be flexible enough to run on a rig when we have multiple screens.

## Beeper

I made a helper class to encapsulate the sound(s) used for correct and incorrect. Should be able to test this easily:

```

```
## Images

The images are loaded to a matlab class that I use for display later in the script. This class will change once we start using the real image set. The usage of the columns 'Img1' and 'Img2' in the trials struct may change as well, depending on the real image set.

Use it to look at the individual images (no scaling - drawn at center) in an open window like this:

```
% Open a window
PsychDefaultSetup(2);
[w, wRect] = PsychImaging('OpenWindow', 0, [.5 .5 .5], [0 0 800 600]);

% load config
cclab = load_local_config();

% image set using file list - change filenames if needed
images = imageset(cclab.ImageFiles);

% display the first image in the set
images.flip(w, 1);

% display the third image in the set at 50% contrast
images.flip(w, 3, .5);
```
