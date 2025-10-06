# EEG Booth setup

Some setup details for the machine used in the EEG booth.

## Operating system

The machine used in the booth runs linux (currently Ubuntu 24.04 LTS). A standard
desktop install was used. The desktop environment is gdm3, and X11 is used for all 
sessions (not Wayland). PTB recommends installing lowlatency kernel, though I 
haven't done that yet. 

## Screen setup

Psychtoolbox has a script 'XorgConfCreator' which works great.... except for us it does NOT mirror the secondary/stimulus screens. We are using an NVIDIA card, and I found the `nvidia-xconfig` would do the trick! 

## PTB and Matlab

Matlab version is 2024b. Pair with PTB version 3.0.19. 

This is the latest FREE version of PTB. Any version after this one requires a license
to allow any MEX files to work. Release notes for PTB indicate that changes to 
Matlab's graphics system starting at 2025a required tweaks to PTB code. 

For these reasons we've chosen to stay at Matlab R2024b and PTB 3.0.19. 

If and when we upgrade, we will probably do two things at once: move to Matlab 
version >= 2025a, AND move to a paid version of PTB. 

On Linux, we set up PTB in this way. This allows for multi-user usage of PTB 
(both Usrey and CCLab use Matlab/PTB). 

1. Run Matlab as root
2. Run SetupPsychtoolbox script. This will save the updated path for all users. 
3. Exit Matlab, run as usual. 

Individual users can alter their own path, but must do so via a startup.m file, 
with `addpath` commands. 

### Millikey

Under Ubuntu 2024.04 LTS, the Millikey presents itself as _three_ devices, 
not one. The function cclabGetMillikeyIndices() has been modified to take the 
_first_ device, which seems to work. It's possible that the rules file can be
modified to fix this. TODO. 


### Check eyetracker operation

1. Open Matlab window
```
> [w,wr,bwr] = makeWindow([], 1);
```

2. Create tracker object (tracker should be on)
```
> tracker=eyetracker(0, [598,336], 920, 'etholog', w);
```

3. Start recording
```
> tracker.start_recording();
```

4. Stop recording
```
> tracker.stop_recording();
```

5. Get edf file
```
> tracker.receive_file('./', 1);
```

You should end up with a file `etholog.edf` in the current folder. 


## ActiView

ActiView is data acquisition software for the ActiveTwo EEG system in the booth. The application is free, and can be downloaded from [BioSemi's download page](https://www.biosemi.com/download.htm). We have installed version 9.02 for Linux along with the LabView RTE according to the instructions provided. 

I modified the ownership of the installed folder to allow users to save configuration files.

- Add new group 'eeg'
```
$ cd /usr/local
$ sudo find ActiView902-Linux/ -type d -exec chmod 2775 {} \;
$ sudo addgroup eeg
$ sudo usermod -a -G eeg pedersen
$ sudo usermod -a -G eeg cclab
$ sudo usermod -a -G eeg usrey
```

With these changes, all users can update and save configuration files to the ActiView folder. Users may not delete other users' files, however. 