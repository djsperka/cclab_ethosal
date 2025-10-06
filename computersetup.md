# EEG Booth setup

Some setup details for the machine used in the EEG booth.

## Operating system

The machine used in the booth runs linux (currently Ubuntu 24.04 LTS). A standard
desktop install was used. The desktop environment is gdm3, and X11 is used for all 
sessions (not Wayland). PTB recommends installing lowlatency kernel, though I 
haven't done that yet. 

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


